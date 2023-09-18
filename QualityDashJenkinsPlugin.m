classdef QualityDashJenkinsPlugin < matlab.buildtool.plugins.BuildRunnerPlugin
    properties (Access = private)
        CIServiceBaseUrl
        BuildId
    end

    methods
        function plugin = QualityDashJenkinsPlugin(ciServiceBaseUrl)
            plugin.CIServiceBaseUrl = ciServiceBaseUrl;
            plugin.BuildId = "";
        end
    end

    methods (Access = protected)
        function runTaskGraph(plugin, pluginData)
             % Populate task graph, build, and build number
            reqBody.buildnum = getenv("BUILD_NUMBER");

            % Let service know build has started
            sendData(reqBody, "http://localhost:8000/builds/add");

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

                matdata = load(matfile);

                disp(matdata);

                r.Passed = sum([matdata.result.Passed]);
                r.Failed = sum([matdata.result.Failed]);
                r.Incomplete = sum([matdata.result.Incomplete]);
                r.NotRun = 0;

                r.hash = getenv("BUILD_NUMBER");

                sendData(r, "http://localhost:8000/results/add")
            % Code issues task
            elseif (isa(t, "matlab.buildtool.tasks.CodeIssuesTask"))
                outs = t.Results.paths();
                matfile = regexp(outs, ".*\.mat$", "match");

                matdata = load(matfile);
                arr = matdata.Issues;

                i.Errors = sum([strcmp(arr.Severity, "error")]);
                i.Warnings = sum([strcmp(arr.Severity, "warning")]);
                i.Info = sum([strcmp(arr.Severity, "info")]);

                i.hash = getenv("BUILD_NUMBER");

                sendData(i, "http://localhost:8000/issues/add");
            end

            disp("Task-DONE");
        end
    end
end

function sendData(data, uri)
req = matlab.net.http.RequestMessage('POST', matlab.net.http.HeaderField("ContentType", "application/json"), matlab.net.http.MessageBody(data));
send(req, uri);
end