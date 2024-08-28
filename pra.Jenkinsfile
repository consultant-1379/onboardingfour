#!/usr/bin/env groovy

def defaultBobImage = 'armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob.2.0:1.7.0-98'
def bob = new BobCommand()
    .bobImage(defaultBobImage)
    .envVars([
        HOME:'${HOME}',
        RELEASE_CANDIDATE: '${RELEASE_CANDIDATE}',
        HELM_USER: 'CBRSCIADM',
        HELM_REPO_TOKEN:'${HELM_REPO_TOKEN}',
        GERRIT_USERNAME:'${GERRIT_USERNAME}',
        GERRIT_PASSWORD:'${GERRIT_PASSWORD}',
    ])
    .needDockerSocket(true)
    .toString()

pipeline {
    agent {
		node {
			label "GE7_Docker"
		}
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        string(name: 'RELEASE_CANDIDATE', description: 'The release candidate version (e.g. 1.0.0-7)')
    }

    stages {
        stage('Clean') {
            steps {
                archiveArtifacts allowEmptyArchive: true, artifacts: 'ruleset2.0.pra.yaml, pra.Jenkinsfile'
                sh "${bob} -r ruleset2.0.pra.yaml clean"
            }
        }

        stage('Init') {
            steps {
                sh "${bob} -r ruleset2.0.pra.yaml init"
                archiveArtifacts 'artifact.properties'
            }
        }

        stage('Publish released Docker Images') {
            steps {
                sh "${bob} -r ruleset2.0.pra.yaml publish-released-docker-image"
            }
        }

        stage('Publish released helm chart') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CBRSCIADM', variable: 'HELM_REPO_TOKEN')]) {
                        sh "${bob} -r ruleset2.0.pra.yaml generate-release-chart publish-released-helm-chart"
                    }
                }
            }
        }

        stage('Create PRA Git Tag') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Gerrit HTTP',
                                 usernameVariable: 'GERRIT_USERNAME',
                                 passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh "${bob} -r ruleset2.0.pra.yaml create-pra-git-tag"
                }
            }
        }

        stage('Increment version prefix') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Gerrit HTTP',
                                 usernameVariable: 'GERRIT_USERNAME',
                                 passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh "${bob} -r ruleset2.0.pra.yaml increment-version-prefix"
                }
            }
        }

        // This stage is executed just for housekeeping to remove the image artifacts from the slave
        stage('Final Cleanup')
        {
            steps {
                sh "${bob} -r ruleset2.0.pra.yaml clean"
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}

// More about @Builder: http://mrhaki.blogspot.com/2014/05/groovy-goodness-use-builder-ast.html
import groovy.transform.builder.Builder
import groovy.transform.builder.SimpleStrategy

@Builder(builderStrategy = SimpleStrategy, prefix = '')
class BobCommand {

    def bobImage = 'bob.2.0:latest'
    def envVars = [:]

    def needDockerSocket = false

    String toString() {
        def env = envVars
                .collect({ entry -> "-e ${entry.key}=\"${entry.value}\"" })
                .join(' ')

        def cmd = """\
            |docker run
            |--init
            |--rm
            |--workdir \${PWD}
            |--user \$(id -u):\$(id -g)
            |-v \${PWD}:\${PWD}
            |-v /etc/group:/etc/group:ro
            |-v /etc/passwd:/etc/passwd:ro
            |-v \${HOME}:\${HOME}
            |${needDockerSocket ? '-v /var/run/docker.sock:/var/run/docker.sock' : ''}
            |${env}
            |\$(for group in \$(id -G); do printf ' --group-add %s' "\$group"; done)
            |--group-add \$(stat -c '%g' /var/run/docker.sock)
            |${bobImage}
            |"""
        return cmd
                .stripMargin()           // remove indentation
                .replace('\n', ' ')      // join lines
                .replaceAll(/[ ]+/, ' ') // replace multiple spaces by one
    }
}
