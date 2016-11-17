properties([[$class: 'GitLabConnectionProperty', gitLabConnection: 'lai1pucreps0001.inf.local']])

node('windows') {

  try {
    // send notification of starting build
    notifyBuild('STARTED')

    // Mark the code checkout 'stage'....
    stage('Checkout') {
      // Checkout code from repository
      checkout scm
    }

    gitlabCommitStatus('powershell') {
      stage('Analysis') {
        // chocolatey package install test
        bat 'Powershell -Command "$Results = Invoke-ScriptAnalyzer -Path *.psm1 -ExcludeRule PSAvoidUsingWMICmdlet, PSShouldProcess;If($Results.Count -gt 0){$Results;Exit 1}Else{$Results;Exit 0}"'
      }
    }
  } catch (any) {

    // if there was an exception thrown, the build failed
    currentBuild.result = "FAILED"
    throw any

  } finally {

    // success or failure, always send notifications
    notifyBuild(currentBuild.result)

  }
}

def notifyBuild(String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus =  buildStatus ?: 'SUCCESSFUL'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"
  def details = """<p>STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
    <p>Check console output at &QUOT;<a href='${env.BUILD_URL}'>${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>&QUOT;</p>"""

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESSFUL') {
    color = 'GREEN'
    colorCode = '#00FF00'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }

  // Send notifications
  slackSend (color: colorCode, message: summary)
}
