require 'blinker/ctf/flag_verifier'
require 'blinker/ctf/challenge_generator'
require 'blinker/ctf/challenge_deployer'
require 'blinker/ctf/deployment_deleter'
require 'blinker/ctf/deadline_enforcer'
require 'blinker/ctf/ctf_director'

module Blinker
  module Ctf
    JOBS = { "flag_verifier" => Blinker::Ctf::FlagVerifier,
             "challenge_generator" => Blinker::Ctf::ChallengeGenerator,
             "challenge_deployer" => Blinker::Ctf::ChallengeDeployer,
             "deployment_deleter" => Blinker::Ctf::DeploymentDeleter,
             "deadline_enforcer" => Blinker::Ctf::DeadlineEnforcer,
             "ctf_director" => Blinker::Ctf::CtfDirector
           }
  end
end
