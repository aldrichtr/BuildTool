@{
    <#
    This file is automatically generated by Plaster when creating
    a project from 'NewModuleProject' template.  The metadata is
    recorded here to mark the template and version that the project
    was created from.
    #>
    Project = @{
        Name = '<%= $PLASTER_PARAM_ModuleName %>'
        Author = '<%= $PLASTER_PARAM_Fullname %>'
        Path = '<%= $PLASTER_DestinationPath %>'
        HostName = '<%= $PLASTER_HostName %>'
    }
    Template = @{
<%
[xml]$manifest = Get-Content -Path "$PLASTER_TemplatePath\plastermanifest.xml"
"        Version = {0}" -f  $manifest.plasterManifest.metadata.version
%>
        Path = '<%= $PLASTER_TemplatePath %>'
        PlasterVersion  = '<%= $PLASTER_Version %>'
    }
    Date = '<%= $PLASTER_Date %>'
    Time = '<%= $PLASTER_Time %>'
}