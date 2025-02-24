function Confirm-PolicyDefinitionsInPolicySetMatch {
    [CmdletBinding()]
    param (
        $Object1,
        $Object2,
        $Definitions
    )

    # check for null or empty scenarios
    if ($Object1 -eq $Object2) {
        return $true
    }
    if ($Object1 -and $Object1 -isnot [System.Collections.IList]) {
        $Object1 = @($Object1)
    }
    if ($Object2 -and $Object2 -isnot [System.Collections.IList]) {
        $Object2 = @($Object2)
    }
    if (($null -eq $Object1 -and $Object2.Count -eq 0) -or ($null -eq $Object2 -and $Object1.Count -eq 0)) {
        return $true
    }
    if ($null -eq $Object1 -or $null -eq $Object2) {
        return $false
    }

    # compare the arrays, assuming that they are in the same order
    if ($Object1.Count -ne $Object2.Count) {
        return $false
    }
    for ($i = 0; $i -le $Object1.Count; $i++) {
        $item1 = $Object1[$i]
        $item2 = $Object2[$i]
        if ($item1 -ne $item2) {
            $policyDefinitionReferenceIdMatches = $item1.policyDefinitionReferenceId -eq $item2.policyDefinitionReferenceId
            if (!$policyDefinitionReferenceIdMatches) {
                return $false
            }
            $policyDefinitionIdMatches = $item1.policyDefinitionId -eq $item2.policyDefinitionId
            if (!$policyDefinitionIdMatches) {
                return $false
            }
            if ($null -ne $item2.definitionVersion) {
                # ignore auto-generated definitionVersion, only compare if Policy definition entry has a definitionVersion
                $deployedPolicyDefinitionVersion = $Definitions[$item1.policyDefinitionId].properties.version
                if ($null -eq $deployedPolicyDefinitionVersion) {
                    # Custom policy definition - version is in a different place
                    $deployedPolicyDefinitionVersion = $Definitions[$item1.policyDefinitionId].metadata.version
                }
                # $definitionVersionMatches = $item1.definitionVersion -eq $item2.definitionVersion
                # if (!$definitionVersionMatches) {
                #     return $false
                # }
                $definitionVersionMatches = Compare-SemanticVersion -Version1 $deployedPolicyDefinitionVersion -Version2 $item2.definitionVersion
                if ($definitionVersionMatches -ne 0) {
                    Write-Verbose "Definition Id: $($item1.policyDefinitionId)"
                    Write-Verbose "DefinitionVersion does not match: Azure: $deployedPolicyDefinitionVersion, Local: $($item2.definitionVersion)"
                    return $false
                }
            }
            $groupNames1 = $item1.groupNames
            $groupNames2 = $item2.groupNames
            if ($null -eq $groupNames1 -and $null -eq $groupNames2 -and $i -eq $Object1.Count) {
                return $true
            }
            if ($null -eq $groupNames1 -or $null -eq $groupNames2 -and $i -eq $Object1.Count) {
                if (($null -ne $groupNames1 -and $groupNames1.Count -eq 0) -or ($null -ne $groupNames2 -and $groupNames2.Count -eq 0)) {
                    return $true
                }
                return $false
            }

            if ($groupNames1.Count -ne $groupNames2.Count) {
                return $false
            }

            if ($groupNames1 -and $groupNames2) {
                $groupNamesCompareResults = Compare-Object -ReferenceObject $groupNames1 -DifferenceObject $groupNames2
                if ($groupNamesCompareResults) {
                    return $false
                }
            }
            
            $parametersUsageMatches = Confirm-ParametersUsageMatches `
                -ExistingParametersObj $item1.parameters `
                -DefinedParametersObj $item2.parameters `
                -CompareValueEntryForExistingParametersObj `
                -CompareValueEntryForDefinedParametersObj
            if (!$parametersUsageMatches) {
                return $false
            }
        }
    }
    return $true
}
