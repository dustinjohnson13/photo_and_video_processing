#!groovy

stage('Run') {
    node {

        def build = "${env.JOB_NAME} - #${env.BUILD_NUMBER}".toString()

        currentBuild.result = "SUCCESS"

        try {

            checkout scm

            sh '. ./functions.sh && verifyRequiredSoftwareExists'
            sh '. ./functions.sh && importPhotosAndVideos'
            sh '. ./functions.sh && createPar2FilesForMiscVideos'

        } catch (err) {
            currentBuild.result = "FAILURE"

            emailext body: "${env.JOB_NAME} failed! See ${env.BUILD_URL} for details.", recipientProviders: [[$class: 'DevelopersRecipientProvider']], subject: "$build failed!"

            throw err
        }
    }
}