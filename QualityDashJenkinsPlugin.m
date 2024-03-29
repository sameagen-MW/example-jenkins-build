classdef QualityDashJenkinsPlugin < matlab.buildtool.plugins.BuildRunnerPlugin
    properties (Access = private)
        CIServiceBaseUrl
        BuildId
    end

    methods
        function plugin = QualityDashJenkinsPlugin(ciServiceBaseUrl)
            plugin.CIServiceBaseUrl = "http://mycluster.ip:32420";
            plugin.BuildId = "";
        end
    end

    methods (Access = protected)
        function runTaskGraph(plugin, pluginData)
             % Populate task graph, build, and build number
            reqBody.buildnum = getenv("BUILD_NUMBER");

            % Let service know build has started
            sendData(reqBody, plugin.CIServiceBaseUrl + "/builds/add");

            % Get build id from response
            % plugin.BuildId = resp.Body.Data.x_id;

            % Run task graph
            runTaskGraph@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            % request = matlab.net.http.RequestMessage('PUT', [matlab.net.http.field.ContentTypeField('application/vnd.api+json'), matlab.net.http.field.AcceptField('application/vnd.api+json')], jsonencode(statusReqBody));
            % request.send(plugin.CIServiceBaseUrl + "/ci-webservice/api/builds/" + plugin.BuildId);
            plugin.BuildId = "";
        end

        function runTask(plugin, pluginData)
            % Get task name and set task status to running
            disp("Running!");
     
            ts = pluginData.TaskGraph.Tasks;
            t = ts(strcmp(ts.Name, pluginData.Name));

            disp(t);

            % Run task
            runTask@matlab.buildtool.plugins.BuildRunnerPlugin(plugin, pluginData);

            % Test task
            if (isa(t, "matlab.buildtool.tasks.TestTask"))
                outs = t.TestResults.paths();
                matfile = regexp(outs, ".*\.mat$", "match");

                if ~isempty(matfile)
                    matdata = load(matfile);
    
                    r.Passed = sum([matdata.result.Passed]);
                    r.Failed = sum([matdata.result.Failed]);
                    r.Incomplete = sum([matdata.result.Incomplete]);
                    r.NotRun = 0;
    
                    r.hash = getenv("BUILD_NUMBER");
    
                    sendData(r, plugin.CIServiceBaseUrl + "/results/add")
                end

                outs = t.CodeCoverageResults.paths();
                matfile = regexp(outs, ".*\.mat$", "match");

                if ~isempty(matfile)
                    matdata = load(matfile);
    
                    cov.function = sum(coverageSummary(matdata.coverage, "function"));
                    cov.statement = sum(coverageSummary(matdata.coverage, "statement"));
                    cov.decision = sum(coverageSummary(matdata.coverage, "decision"));
                    cov.condition = sum(coverageSummary(matdata.coverage, "condition"));
                    cov.mcdc = sum(coverageSummary(matdata.coverage, "mcdc"));

                    cov.hash = getenv("BUILD_NUMBER");

                    sendData(cov, plugin.CIServiceBaseUrl + "/coverage/add");
                end

            % Code issues task
            elseif (isa(t, "matlab.buildtool.tasks.CodeIssuesTask"))
                outs = t.Results.paths();
                matfile = regexp(outs, ".*\.mat$", "match");

                matdata = load(matfile);

                disp(matdata.issues);

                arr = matdata.issues.Issues;

                i.Errors = sum([strcmp(arr.Severity, "error")]);
                i.Warnings = sum([strcmp(arr.Severity, "warning")]);
                i.Info = sum([strcmp(arr.Severity, "info")]);

                i.hash = getenv("BUILD_NUMBER");

                sendData(i, plugin.CIServiceBaseUrl + "/issues/add");
            end

            disp("Task-DONE");
        end
    end
end

function sendData(data, uri)
req = matlab.net.http.RequestMessage('POST', matlab.net.http.HeaderField("ContentType", "application/json"), matlab.net.http.MessageBody(data));
send(req, uri);
end
