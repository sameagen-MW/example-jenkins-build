runner = matlab.buildtool.BuildRunner.withTextOutput();
runner.addPlugin(QualityDashJenkinsPlugin("http://localhost:8080"))
runner.run(buildfile(), "ContinueOnFailure", true);