package backend;

class BuildInfo
{
	public static final githubDevBuild:Bool = BuildInfoGenerated.githubDevBuild;
	public static final commit:String = BuildInfoGenerated.commit;
	public static final runId:String = BuildInfoGenerated.runId;

	public static function shortCommit():String
	{
		return commit != null && commit.length > 7 ? commit.substr(0, 7) : commit;
	}

	public static function versionLine():String
	{
		if (!githubDevBuild)
			return "";

		var parts:Array<String> = [];
		if (runId != null && runId.length > 0)
			parts.push('#' + runId);
		if (commit != null && commit.length > 0)
			parts.push(shortCommit());

		return parts.length > 0 ? 'GitHub Build ' + parts.join(' | ') : 'GitHub Build';
	}
}

