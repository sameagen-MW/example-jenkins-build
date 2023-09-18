function plan = buildfile
import matlab.buildtool.tasks.*;
plan = buildplan(localfunctions);

plan("clean") = CleanTask();
plan("lint") = CodeIssuesTask("tests", Results="results/lint.mat");
plan("test") = TestTask("tests", TestResults="results/tests.mat");

plan.DefaultTasks = ["lint", "test"];
end