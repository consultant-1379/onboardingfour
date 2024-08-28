#!/usr/bin/env groovy

def defaultBobImage = 'armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob.2.0:1.7.0-98'
def bob = new BobCommand()
    .bobImage(defaultBobImage)
    .envVars([
        HELM_REPO_TOKEN:'${HELM_REPO_TOKEN}',
        HOME:'${HOME}',
        RELEASE:'${RELEASE}',
        KUBECONFIG:'${KUBECONFIG}',
        SITE_VALUES:'${SITE_VALUES}',
        USER:'${USER}',
		XRAY_USER:'${CREDENTIALS_XRAY_SELI_ARTIFACTORY_USR}',
        XRAY_TOKEN:'${CREDENTIALS_XRAY_SELI_ARTIFACTORY_PSW}'
    ])
    .needDockerSocket(true)
    .toString()

def LOCKABLE_RESOURCE_LABEL = "kaas"

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

    environment {
        RELEASE = "true"
        KUBECONFIG = "${WORKSPACE}/.kube/config"
        SITE_VALUES = "${WORKSPACE}/k8s-test/hahn166_site-values.yaml"
		CREDENTIALS_XRAY_SELI_ARTIFACTORY = credentials('OSSCNCI')
    }

    stages {
        stage('Clean') {
            steps {
                archiveArtifacts allowEmptyArchive: true, artifacts: 'ruleset2.0.yaml, publish.Jenkinsfile'
                sh "${bob} clean"
            }
        }

        stage('Init') {
            steps {
                sh "${bob} init-drop"
                archiveArtifacts 'artifact.properties'
            }
        }

        stage('Lint') {
            steps {
                parallel(
                    "lint helm": {
                        sh "${bob} lint:helm"
                    },
                    "lint helm design rule checker": {
                        sh "${bob} lint:helm-chart-check"
                    }
                )
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: '.bob/design-rule-check-report.*'
                }
            }
        }

        stage('Image') {
            steps {
                sh "${bob} image"
                sh "${bob} image-dr-check"
            }
            post {
                always {
                    archiveArtifacts allowEmptyArchive: true, artifacts: '.bob/check-image/image-design-rule-check-report.*, .bob/check-init-image/image-design-rule-check-report.*'
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CBRSCIADM', variable: 'HELM_REPO_TOKEN')]) {
                        sh "${bob} package"
                    }
                }
            }
        }

        stage('K8S Resource Lock') {
		options {
                lock(label: LOCKABLE_RESOURCE_LABEL, variable: 'RESOURCE_NAME', quantity: 1)
            }
			environment {
                // RESOURCE_NAME = hahn166_namespace2
                K8S_CONFIG_FILE_ID = sh(script: "echo \${RESOURCE_NAME} | cut -d'_' -f1", returnStdout: true).trim()
                // K8S_CONFIG_FILE_ID = hahn166
            }
             stages {
				stage('Vulnerability Analysis and K8S Test'){
					parallel{
					//stage('K8S Test'){
						//stages{
							//stage('Helm Install') {
								//steps {
									//echo "Inject kubernetes config file (${env.K8S_CONFIG_FILE_ID}) based on the Lockable Resource name: ${env.RESOURCE_NAME}"
									//configFileProvider([configFile(fileId: "${K8S_CONFIG_FILE_ID}", targetLocation: "${env.KUBECONFIG}")]) {
										//sh "${bob} helm-dry-run"
										//sh "${bob} create-namespace"
										//sh "${bob} helm-install"
										//sh "${bob} healthcheck"
									//}
								//}
								//post {
									//failure {
										//sh "${bob} collect-k8s-logs || true"
										//archiveArtifacts allowEmptyArchive: true, artifacts: 'k8s-logs/**/*.*'
										//sh "${bob} delete-namespace"
									//}
								//}
							//}
							//stage('K8S Test') {
								//steps {
									//echo 'sh "${bob} helm-test"'
								//}
								//post {
									//failure {
										//sh "${bob} collect-k8s-logs || true"
										//archiveArtifacts allowEmptyArchive: true, artifacts: 'k8s-logs/**/*.*'
									//}
									//cleanup {
										//sh "${bob} delete-namespace"
									//}
								//}
							//}
						//}
					//}
					stage('Kubehunter') {
						steps {
							//configFileProvider([configFile(fileId: "kubehunter_config.yaml", targetLocation: "${env.WORKSPACE}/config/")]) {}
							//sh "${bob} kube-hunter"
							//archiveArtifacts "build/kubehunter-report/**/*"
							echo "Kubehunter"
						}
					}
					stage('Kubeaudit') {
						steps {
						  //configFileProvider([configFile(fileId: "kubeaudit_config.yaml", targetLocation: "${env.WORKSPACE}/config/")]) {}
						  sh "${bob} kube-audit"
						  archiveArtifacts 'build/kube-audit-report/**/*'
						}
					}
					stage('Kubesec') {
						steps {
						  //configFileProvider([configFile(fileId: "kubesec_config.yaml", targetLocation: "${env.WORKSPACE}/config/")]) {}
						  sh "${bob} kube-sec"
						  archiveArtifacts 'build/kubesec-reports/**/*'
						}
					}
					stage('trivy') {
						steps {
						  sh "${bob} trivy-inline-scan"
						  archiveArtifacts 'build/trivy-reports/**.*'
						  archiveArtifacts 'build/trivy-reports/trivy_metadata.properties'
						}
					}
					stage('Hadolint') {
						steps {
							//configFileProvider([configFile(fileId: "hadolint_config.yaml", targetLocation: "${env.WORKSPACE}/config/")]) {}
							sh "${bob} hadolint-scan"
							archiveArtifacts "build/hadolint-scan/**.*"
						}
					}
					stage('Anchore-Grype and X-Ray'){
						stages{
							stage('Anchore-Grype') {
								steps {
									sh "${bob} anchore-grype-scan"
									archiveArtifacts 'build/anchore-reports/**.*'
								}
							}
							stage('X-Ray'){
								steps{
									sleep(60)
									sh "${bob} fetch-xray-report"
									archiveArtifacts 'build/xray-reports/xray_report.json'
									archiveArtifacts 'build/xray-reports/raw_xray_report.json'
								}
							}
						}
					}
				}
				}
				stage('Generate Vulnerability report V2.0'){
                            steps {
                                sh "${bob} generate-VA-report-V2:no-upload"
                                archiveArtifacts allowEmptyArchive: true, artifacts: 'build/Vulnerability_Report_2.0.md'
                            }
                        }
            }
		}
				
        stage('Publish') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'CBRSCIADM', variable: 'HELM_REPO_TOKEN')]) {
                        sh "${bob} publish"
                    }
                }
            }
		}
	}
    post {
        always {
			sh "${bob} cleanup-trivy-anchore-images"
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