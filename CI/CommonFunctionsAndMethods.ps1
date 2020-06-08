$MergeHashTables = {param([HashTable]$base,[HashTable]$new);$new.GetEnumerator()|%{$base.remove($_.Key);$base += @{$_.Key=$_.Value}};$base;}
$AddTagsToResourceGroup = {param([String]$ResourceGroupName,[HashTable]$newTags);$RG = Get-AzResourceGroup -name $ResourceGroupName;$RG|SetAzResourceGroup -Tags $MergeHashTables.Invoke($RG.Tags,$newTags);}
