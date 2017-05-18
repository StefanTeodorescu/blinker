function Challenge(id) {
    var self = this;

    self.id = id;
    self.description = ko.observable(null);
    self.deadline = ko.observable(null);
    self.deployment = ko.observable(null);
    self.deploymentDiagnostic = ko.observable(null);
    self.deploymentFailed = ko.observable(false);
}

function ViewModel(uuid) {
    var self = this;

    self.uuid = uuid;

    self.status = ko.observable("loading");
    self.challenges = {};
    self.challengeId = ko.observable(null);
    self.challenge = ko.computed(function() {
        return self.challengeId() && self.challenges[self.challengeId()];
    });
    self.challengeDescription = ko.computed(function() {
        return self.challenge() && self.challenge().description();
    });
    self.challengePending = ko.observable(false);
    self.flagPending = ko.observable(false);
    self.flagRejected = ko.observable(false);
    self.flagAccepted = ko.observable(false);
    self.skipRequested = ko.observable(false);
    self.skipPending = ko.observable(false);
    self.deadline = ko.computed(function() {
        return self.challenge() && self.challenge().deadline();
    });
    self.timeUp = ko.observable(false);
    self.deployment = ko.computed(function() {
        return self.challenge() && self.challenge().deployment();
    });
    self.deploymentDiagnostic = ko.computed(function() {
        return self.challenge() && self.challenge().deploymentDiagnostic();
    });
    self.deploymentDiagnosticNice = ko.computed(function() {
        switch (self.deploymentDiagnostic()) {
        case "allocating_resources":
            return "Cloud resources are being allocated. This should only take a few seconds, although very rarely may take up to 10 minutes.";
        case "initializing_network":
            return "The network is being set up for your server. This should only take a few seconds.";
        case "creating_vm":
            return "Your server is being created. This may take a few minutes, but the whole process altogether should take less than 10 minutes.";
        case "provisioning_vm":
            return "The exercise is being installed on your server. This may take a few minutes, but the whole process altogether should take less than 10 minutes.";
        case "finalizing_vm":
            return "The server is being reconfigured for internet access. This may take a few minutes, but the whole process altogether should take less than 10 minutes.";
        case "error":
            return "An error happened while deploying your server. Please contact me on the email address below.";
        case "ready":
            return "Your server is ready, you should see the connection details in a second.";
        default:
            return "The server is in an unknown state. This is a problem with the experiment website. Please notify me on the email address below.";
        }
    });

    self.queuePosition = ko.observable(null);
    self.communicationProblem = ko.observable(false);
    self.serverProblem = ko.observable(false);
    self.actionRequested = ko.observable(null);
    self.actionFailed = ko.observable(false);
    self.generationFailed = ko.observable(false);
    self.deploymentFailed = ko.computed(function() {
        return self.challenge() && self.challenge().deploymentFailed();
    });

    self.flagToSubmit = ko.observable("");
    self.disableActions = ko.computed(function() {
        return self.flagPending() || self.skipPending() || self.skipRequested() || self.actionRequested() != null;
    });

    self.refreshPeriod = 1000;
    self.lastEventId = 0;

    self.processEvent = function(ev) {
        self.lastEventId = ev.id;
        switch (ev.event) {
        case "ctf_started":
            self.status("started");
            break;
        case "ctf_completed":
            self.status("completed");
            location.reload(true);
            break;
        case "flag_submitted":
            self.flagPending(true);
            self.flagRejected(false);
            self.flagAccepted(false);
            self.flagToSubmit("");
            self.actionFailed(false);
            break;
        case "flag_rejected":
            self.flagPending(false);
            self.flagRejected(true);
            self.flagAccepted(false);
            break;
        case "flag_accepted":
            self.flagPending(false);
            self.flagRejected(false);
            self.flagAccepted(true);
            break;
        case "challenge_requested":
            self.challengePending(true);
            self.actionFailed(false);
            break;
        case "challenge_generated":
            self.challenges[ev.challenge] = new Challenge(ev.challenge);
            break;
        case "challenge_assigned":
            self.challengeId(ev.challenge);
            self.challenge() && self.challenge().description(ev.message);
            self.challengePending(false);
            self.flagAccepted(false);
            self.timeUp(false);
            break;
        case "challenge_deadline":
            self.challenges[ev.challenge] && self.challenges[ev.challenge].deadline(ev.message);
            break;
        case "challenge_closed":
            self.challengeId(null);
            self.skipRequested(false);
            self.skipPending(false);
            break;
        case "deployment_update":
            self.challenges[ev.challenge] && self.challenges[ev.challenge].deploymentDiagnostic(ev.message);
            break;
        case "deployment_complete":
            self.challenges[ev.challenge] && self.challenges[ev.challenge].deployment(ev.message);
            break;
        case "skip_requested":
            self.skipPending(true);
            self.actionFailed(false);
            break;
        case "challenge_generator_failed":
            self.generationFailed(true);
            self.refreshPeriod(null);
            break;
        case "challenge_deployer_failed":
            self.challenges[ev.challenge] && self.challenges[ev.challenge].deploymentFailed(true);
            break;
        }
    };

    self.refresh = function() {
        $.ajax({
            data: { since: self.lastEventId },
            dataType: "json",
            success: function(data, status, xhr) {
                self.communicationProblem(false);
                self.serverProblem(false);
                self.refreshPeriod = 1000;

                if (self.status() && data.status) {
                    self.status(data.status);
                }

                if (data.events && data.events instanceof Array) {
                    data.events.forEach(self.processEvent);
                }

                if (data.queues && data.queues.length > 0) {
                    var max_queue = data.queues.map(function (q) { return q['position']; }).reduce(function(i, s) { return (i > s) ? i : s; });
                    self.queuePosition(max_queue);
                } else {
                    self.queuePosition(null);
                }

                self.scheduleRefresh();
            },
            error: function(xhr, status, thrown) {
                if (xhr.status == 500) {
                    self.serverProblem(true);
                    self.refreshPeriod = null;
                } else {
                    self.communicationProblem(true);
                    if (self.refreshPeriod < 60000)
                        self.refreshPeriod *= 2;
                }

                self.scheduleRefresh();
            }
        });
    };

    self.scheduleRefresh = function() {
        if (self.refreshPeriod != null)
            window.setTimeout(self.refresh, self.refreshPeriod);
    };

    self.postAction = function(data) {
        self.actionFailed(false);
        $.ajax({ method: 'POST',
                 data: data,
                 success: function(data, status, xhr) {
                     self.actionRequested(null);
                 },
                 error: function(xhr, status, thrown) {
                     self.actionFailed(true);
                 }});
    };

    self.submitFlag = function() {
        self.actionRequested("submit flag");
        self.postAction({ flag: self.flagToSubmit });
    };

    self.skipChallenge = function() {
        self.actionRequested("skip challenge");
        self.skipRequested(true);
        self.postAction({ skip: true });
    };

    self.proceed = function() {
        self.actionRequested("proceed");
        self.postAction({});
    };
}

var q = document.location.search;
if (q.startsWith('?')) q = q.substring(1);
var uuid = decodeURIComponent((q.split('&').filter(function (param) { return param.startsWith('uuid='); }).slice(-1)[0]||'').substring(5));

var vm = new ViewModel(uuid);

ko.applyBindings(vm);

vm.scheduleRefresh();
