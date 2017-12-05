#load "nuget:https://www.myget.org/F/cake-contrib/api/v2?package=Cake.Wyam.Recipe&prerelease"

Environment.SetVariableNames(
    githubPasswordVariable: "GITHUB_TOKEN",
    wyamAccessTokenVariable: "GITHUB_TOKEN"
);

BuildParameters.SetParameters(
    context: Context,
    buildSystem: BuildSystem,
    title: "Wormies-AU-Helpers",
    repositoryOwner: "WormieCorp",
    appVeyorAccountName: "AdmiringWorm",
    wyamRecipe: "Docs",
    wyamTheme: "Samson",
    webLinkRoot: "wormies-au-helpers"

);

BuildParameters.PrintParameters(Context);

Build.Run();
