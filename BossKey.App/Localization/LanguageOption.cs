namespace BossKey.App.Localization;

public sealed record LanguageOption(
    string Code,
    string DisplayName,
    string InstalledVersion,
    string LatestVersion)
{
    public string DisplayText
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(InstalledVersion)
                && !string.IsNullOrWhiteSpace(LatestVersion)
                && !string.Equals(InstalledVersion, LatestVersion, StringComparison.OrdinalIgnoreCase))
            {
                return $"{DisplayName} ({InstalledVersion} -> {LatestVersion})";
            }

            var version = !string.IsNullOrWhiteSpace(LatestVersion)
                ? LatestVersion
                : InstalledVersion;
            return string.IsNullOrWhiteSpace(version)
                ? DisplayName
                : $"{DisplayName} ({version})";
        }
    }

    public override string ToString()
    {
        return DisplayText;
    }
}
