function plan = buildfile
import matlab.buildtool.tasks.*;
plan = buildplan(localfunctions);

disp(pwd);

plan("clean") = CleanTask();
plan("lint") = CodeIssuesTask("tests", Results="results/lint.mat");
plan("test") = TestTask("tests", TestResults="results/tests.mat", SourceFiles="tests", CodeCoverageResults="results/cov.mat");
plan("test").Dependencies = "lint";

plan.DefaultTasks = ["lint", "test"];
end