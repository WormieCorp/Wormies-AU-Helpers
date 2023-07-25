#load "nuget:?package=Cake.Wyam.Recipe&version=1.0.0"

Environment.SetVariableNames(
    githubPasswordVariable: "GITHUB_TOKEN",
    wyamAccessTokenVariable: "GITHUB_TOKEN"
);

BuildParameters.SetParameters(
    context: Context,
    buildSystem: BuildSystem,
    title: "Wormies-AU-Helpers",
    repositoryOwner: "WormieCorp",
    repositoryName: "Wormies-AU-Helpers",
    appVeyorAccountName: "AdmiringWorm",
    wyamRecipe: "Docs",
    wyamTheme: "Samson",
    webLinkRoot: "Wormies-AU-Helpers"

);

BuildParameters.PrintParameters(Context);

((CakeTask)BuildParameters.Tasks.PublishDocumentationTask.Task).Actions.Clear();
BuildParameters.Tasks.PublishDocumentationTask.Does(() => RequireTool(KuduSyncTool, () => {
        if(BuildParameters.CanUseWyam)
        {
            var sourceCommit = GitLogTip("../");

            var publishFolder = BuildParameters.WyamPublishDirectoryPath.Combine(DateTime.Now.ToString("yyyyMMdd_HHmmss"));
            Information("Publishing Folder: {0}", publishFolder);
            Information("Getting publish branch...");
            GitClone(BuildParameters.Wyam.DeployRemote, publishFolder, new GitCloneSettings{ BranchName = BuildParameters.Wyam.DeployBranch });

            Information("Sync output files...");
            Kudu.Sync(BuildParameters.Paths.Directories.PublishedDocumentation, publishFolder, new KuduSyncSettings {
                ArgumentCustomization = args=>args.Append("--ignore").AppendQuoted(".git;CNAME")
            });

            if (GitHasUncommitedChanges(publishFolder))
            {
                Information("Stage all changes...");
                GitAddAll(publishFolder);

                Information("Commit all changes...");
                GitCommit(
                    publishFolder,
                    sourceCommit.Committer.Name,
                    sourceCommit.Committer.Email,
                    string.Format("AppVeyor Publish: {0}\r\n{1}", sourceCommit.Sha, sourceCommit.Message)
                );

                Information("Pushing all changes...");
                GitPush(publishFolder, BuildParameters.Wyam.AccessToken, "x-oauth-basic", BuildParameters.Wyam.DeployBranch);
            }
        }
        else
        {
            Warning("Unable to publish documentation, as not all Wyam Configuration is present");
        }
    }));

Build.Run();
