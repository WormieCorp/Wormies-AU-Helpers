#load "nuget:?package=Cake.Wyam.Recipe"

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
    webLinkRoot: "wormies-au-helpers"

);

BuildParameters.PrintParameters(Context);

Build.Run();
