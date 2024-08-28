#!/usr/bin/env groovy

def defaultBobImage = 'armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob.2.0:1.7.0-98'
def bob = new BobCommand()
    .bobImage(defaultBobImage)
    .envVars([
        IMAGE_REPO:'${IMAGE_REPO}',
        IMAGE_TAG:'${IMAGE_TAG}',
        PACKAGE_REPO_URL:'${PACKAGE_REPO_URL}',
        CBOS_COMMIT_MESSAGE:'${CBOS_COMMIT_MESSAGE}',
        GERRIT_USERNAME:'${GERRIT_USERNAME}',
        GERRIT_PASSWORD:'${GERRIT_PASSWORD}'
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
        string(name: 'IMAGE_REPO', description: 'The image repo for base OS (e.g. armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release)')
        string(name: 'IMAGE_TAG', description: 'The image tag for base OS (e.g. 1.0.0-7)')
        string(name: 'PACKAGE_REPO_URL', description: 'The URL for CBOS zypper repo')
        string(name: 'CBOS_COMMIT_MESSAGE', description: 'The Commit Message from upstream CBOS build')
    }

    stages {
        stage('Update Base OS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Gerrit HTTP',
                                 usernameVariable: 'GERRIT_USERNAME',
                                 passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh "${bob} create-new-cbos-patch"
                }
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
