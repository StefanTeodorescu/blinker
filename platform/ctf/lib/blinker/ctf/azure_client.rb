require 'json'

require 'azure_mgmt_resources'
require 'azure_mgmt_dns'
require 'azure_mgmt_network'

# HACK MsRest is broken: https://github.com/Azure/azure-sdk-for-ruby/issues/639
module MsRest
  class HttpOperationRequest
    def build_path
      template = path_template.dup
      path_params.each{ |key, value| template["{#{key}}"] = ERB::Util.url_encode(value) if template.include?("{#{key}}") } unless path_params.nil?
      skip_encoding_path_params.each{ |key, value| template["{#{key}}"] = value } unless skip_encoding_path_params.nil?
      path = URI.parse(template.gsub(/([^:]|\A)\/\//, '\1/'))
      unless skip_encoding_query_params.nil?
        path.query = [(path.query || ""), skip_encoding_query_params.reject{|_, v| v.nil?}.map{|k,v| "#{k}=#{v}"}].join('&')
      end
      path
    end
  end
end

module Blinker
  module Ctf
    class ChallengeDeployment
      attr_reader :domain
      attr_reader :reason

      def initialize resource_client, resource_group, name, promise
        @resource_client, @resource_group = resource_client, resource_group
        @name, @promise = name, promise

        @promise.on_success { |domain|
          @domain = domain
        }

        @promise.rescue {
          @reason = @promise.reason
        }
      end

      def in_progress?
        !@promise.complete?
      end

      def succeeded?
        !in_progress? and !failed?
      end

      def failed?
        @promise.rejected?
      end

      def state
        ops = operations

        ready = lambda { |op| op.properties.provisioning_state == 'Succeeded' }

        storage_account = ops.select { |op| op.properties.target_resource&.resource_type&.start_with? 'Microsoft.Storage/storageAccounts' }
        return :allocating_resources if ops.empty? or !storage_account.all? &ready

        network = ops.select { |op| op.properties.target_resource&.resource_type&.start_with? 'Microsoft.Network/' }

        return :initializing_network unless !network.empty? and network.all? &ready

        vm = ops.select { |op| op.properties.target_resource&.resource_type == 'Microsoft.Compute/virtualMachines' }

        return :creating_vm unless !vm.empty? and vm.all? &ready

        extension = ops.select { |op| op.properties.target_resource&.resource_type == 'Microsoft.Compute/virtualMachines/extensions' }

        return :provisioning_vm unless !extension.empty? and extension.all? &ready
        return :finalizing_vm if in_progress?
        return :ready if succeeded?
        :error
      end

      def wait seconds
        @promise.wait seconds
      end

      protected
      def operations
        return [] unless @resource_client.deployments.check_existence @resource_group, @name

        ops = @resource_client.deployment_operations.list @resource_group, @name
      end
    end

    class AzureClient
      attr_reader :resource_group

      def initialize opts
        subscription_id = opts[:subscription_id]
        tenant_id = opts[:tenant_id]
        client_id = opts[:client_id]
        client_secret = opts[:client_secret]

        @resource_group = opts[:resource_group]
        @challenge_domain = opts[:challenge_domain]
        @ssh_key = File.read opts[:ssh_key]

        provider = MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, client_secret)
        credentials = MsRest::TokenCredentials.new(provider)

        @resource_client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
        @resource_client.subscription_id = subscription_id

        @dns_client = Azure::ARM::Dns::DnsManagementClient.new(credentials)
        @dns_client.subscription_id = subscription_id

        @network_client = Azure::ARM::Network::NetworkManagementClient.new(credentials)
        @network_client.subscription_id = subscription_id

        unless @resource_client.resource_groups.list.one? { |rg| rg.name == @resource_group }
          raise "resource group '#{@resource_group}' does not exist"
        end

        unless @dns_client.zones.get(@resource_group, @challenge_domain)
          raise "DNS zone '#{challenge_domain}' does not exist in resource group '#{@resource_group}'"
        end
      end

      def deploy challenge_id, provision_script
        name = "challenge-#{challenge_id}"
        deployment = deployment_from 'vm', sshKeyData: @ssh_key, challengeId: challenge_id, challengeDomain: @challenge_domain, provisionScript: provision_script

        promise = @resource_client.deployments.create_or_update_async(@resource_group, name, deployment).flat_map { |result|
          out = result.body.properties.outputs.map { |k, v| [k, v['value']] }.to_h
          nic = @network_client.network_interfaces.get_async(@resource_group, out['nic']).then { |result| result.body }
          prod_subnet = @network_client.subnets.get_async(@resource_group, out['vnet'], out['prod_subnet']).then { |result| result.body }

          Concurrent::Promise.fulfill(out).zip(nic, prod_subnet)
        }.flat_map { |out, nic, prod_subnet|
          nic.network_security_group = prod_subnet.network_security_group

          nic.ip_configurations.each { |ip_config|
            ip_config.subnet = prod_subnet
          }

          @network_client.network_interfaces.create_or_update_async(@resource_group, nic.name, nic).then {
            out['fqdn']
          }
        }

        ChallengeDeployment.new @resource_client, @resource_group, name, promise
      end

      def delete challenge_id
        @dns_client.record_sets.delete(@resource_group, @challenge_domain, challenge_id, 'CNAME')

        template = JSON.parse(File.read(File.join(__dir__, "../../../templates/vm.json")))

        # challenge_id is alphanumeric, so no escaping needed
        @resource_client.resources.list("tagname eq 'ctf-challenge-id' and tagvalue eq '#{challenge_id}'").sort_by { |resource|
          # the VM must be deleted first to release the NIC, which must be deleted to release the IP
          case resource.type
          when 'Microsoft.Compute/virtualMachines' then 1
          when 'Microsoft.Network/networkInterfaces' then 2
          when 'Microsoft.Storage/storageAccounts' then 4
          else 3
          end
        }.each { |resource|
          api_version = template['resources'].find { |r| r['type'] == resource.type }['apiVersion']
          @resource_client.resources.delete_by_id resource.id, api_version
        }
      end

      protected
      def deployment_from template, params
        Azure::ARM::Resources::Models::Deployment.new.tap { |deployment|
          deployment.properties = Azure::ARM::Resources::Models::DeploymentProperties.new.tap { |prop|
            prop.template = JSON.parse(File.read(File.join(__dir__, "../../../templates/#{template}.json")))
            prop.mode = Azure::ARM::Resources::Models::DeploymentMode::Incremental
            prop.parameters = params.map { |k, v| [k,  { :value => v }] }.to_h
          }
        }
      end
    end
  end
end
