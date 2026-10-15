$ErrorActionPreference = 'Stop'

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  Write-Error 'Java was not found. Install JDK 21 and set JAVA_HOME/PATH.'
}
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
  Write-Error 'Maven was not found. Install Maven and add mvn to PATH.'
}

mvn spring-boot:run
