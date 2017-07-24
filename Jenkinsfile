#!groovy

import groovy.json.JsonOutput

stage('Run') {
    node {

        currentBuild.result = "SUCCESS"

        try {

            checkout scm

            sh '. ./functions.sh && verifyRequiredSoftwareExists'
            sh '. ./functions.sh && importPhotosAndVideos'
            sh '. ./functions.sh && createPar2FilesForMiscVideos'

        } catch (err) {
            currentBuild.result = "FAILURE"

            def build = "${env.JOB_NAME} - #${env.BUILD_NUMBER}".toString()
            def notifierEndpoint = "${env.NOTIFIER_ENDPOINT}".toString()
            def emailAddress = "${env.EMAIL}".toString()

            def email = [to: emailAddress, from: emailAddress, subject: "$build failed!", body: "${env.JOB_NAME} failed! See ${env.BUILD_URL} for details."]
            def notify = [email: email]

            sh "curl -X 'POST' $notifierEndpoint -H 'Content-Type: application/json' -d '${JsonOutput.toJson(notify)}'"

            throw err
        }
    }
}