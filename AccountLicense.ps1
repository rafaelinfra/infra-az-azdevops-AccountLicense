param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("","")] ## Incluir a organization para validação
    [String] $organization
)

az extension add --name azure-devops --allow-preview true

$azuredevops = Get-AutomationVariable -Name #<Inclui o token PAT do azure devops com as devidas permissões>
echo  $azuredevops | az devops login --org https://dev.azure.com/$organization

#variável que contém os usuários do devops (top 500)
$topList = az devops user list --top 500 -o json | ConvertFrom-json

#itens de inialização
$usu45Dias = @()
$anyuser = $true

#foreach para criação de variavel e relizar as alterações necessárias
$topList.items | ForEach-Object {
#$topList | ForEach-Object {
    $user = $_.user.principalName
    $sku = $_.accessLevel.accountLicenseType
    $lastAccess = $_.lastAccessedDate
    $today = Get-Date
    #alteração de formato de data para conseguir fazer a comparação depois
    $fixLastAccess = [DateTime]::Parse($lastAccess)
    $difDay = ($today - $fixLastAccess).Days
    #foreach onde analisa os usuários com 45 dias sem acesso que não são stakeholders - considera todo o resto
    foreach ($diferent in $difDay) {
        if ($diferent -gt 45 -and $sku -ne 'stakeholder') {
            $usu45Dias += $user
            $anyuser = $false
            az devops user update --user $user --license-type 'stakeholder'
        }
    }
}
if ($anyuser) {
    Write-Output "Não há usuário maior que 45 dias sem utilizar o Azure DevOps."
} else {
    Write-Output "Lista de usuários com mais de 45 dias sem acessar o Azure DevOps:" $usu45Dias
    $numeroDeUsuarios = $usu45Dias.Count
    Write-Output "Total de usuários: $numeroDeUsuarios"
}