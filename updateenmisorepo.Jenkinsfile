#!/usr/bin/env groovy

def defaultBobImage = 'armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob.2.0:latest'
def bob = new BobCommand()
    .bobImage(defaultBobImage)
    .envVars([
        ENM_DROP:'${ENM_DROP}',
        ENM_ISO_VERSION:'${ENM_ISO_VERSION}',
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
        string(name: 'ENM_DROP', description: 'The sprint which ENM ISO version is from (e.g. 22.02)')
        string(name: 'ENM_ISO_VERSION', description: 'The ENM ISO version (e.g. 2.2.49)')
    }

    stages {
        stage('Update ENM ISO') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'Gerrit HTTP',
                                 usernameVariable: 'GERRIT_USERNAME',
                                 passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh "${bob} create-new-enm-iso-patch"
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
