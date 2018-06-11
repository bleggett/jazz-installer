# Make current user owner of these files
execute 'chownjenkinsfiles' do
  command "sudo chown -R $(whoami) #{node['script_root']}"
end

# Add execute bit to all shell scripts
execute 'chmodjenkinsscripts' do
  command "find #{node['script_root']}/jobs -type f -iname \"*.sh\" -exec chmod +x {} \\;"
end

execute 'concatJenkinsPlugins' do
  command "cat #{node['script_root']}/plugins/plugins0* > #{node['chef_root']}/plugins.tar"
end

execute 'extractJenkinsPlugins' do
  command "tar -xf #{node['chef_root']}/plugins.tar -C /var/lib/jenkins/"
end

# Clean up the plugin tar from previous step, it is rather large
file "#{node['chef_root']}/plugins.tar" do
  action :delete
end

# Copy authfile
cookbook_file "#{node['chef_root']}/authfile" do
  source 'authfile'
  action :create
end

directory '/var/lib/jenkins/workspace' do
  owner 'jenkins'
  group 'jenkins'
  mode '0777'
  recursive true
end

# If we're on RHEL, adjust Java memory options
# (not sure if this is needed, or actually RHEL-specific, but keeping it)
execute 'resizeJenkinsMemorySettings' do
  only_if { node['platform_family'].include?('rhel') }
  command "sudo sed -i 's/JENKINS_JAVA_OPTIONS=.*.$/JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=512m\"/' /etc/sysconfig/jenkins"
end

service 'jenkins' do
  action :restart
end

# Wait a bit, Java apps don't coldboot very quickly...
execute 'waitForFirstJenkinsRestart' do
  command 'sleep 30'
end

# Try to fetch the version-appropriate Jenkins CLI jar from the server itself.
execute 'copyJenkinsClientJar' do
  command "curl -sL http://#{node['jenkinselb']}/jnlpJars/jenkins-cli.jar -o #{node['chef_root']}/jenkins-cli.jar; chmod 755 #{node['jenkins']['clientjar']}"
end

bash 'createJobExecUser' do
  code <<-EOH
       echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount(\"jobexec\", \"jenkinsadmin\")' | java -jar #{node['jenkins']['clientjar']} -auth @#{node['authfile']} -s http://#{node['jenkinselb']}/ groovy =
  EOH
end

cookbook_file "#{node['chef_root']}/encrypt.groovy" do
  source 'encrypt.groovy'
  action :create
end

cookbook_file "#{node['chef_root']}/xmls.tar" do
  source 'xmls.tar'
  action :create
end

execute 'extractXmls' do
  command "tar -xvf #{node['chef_root']}/xmls.tar"
  cwd '/var/lib/jenkins'
end

cookbook_file '/var/lib/jenkins/config.xml' do
  source 'config.xml'
  action :create
end

cookbook_file '/var/lib/jenkins/credentials.xml' do
  source 'credentials.xml'
  action :create
end

# Configure Gitlab Plugin
bash 'configuregitlabplugin' do
  only_if { node['scm'] == 'gitlab' }
  code <<-SCRIPT
    sed -i "s/ip/#{node['scmelb']}/g" /var/lib/jenkins/com.dabsquared.gitlabjenkins.connection.GitLabConnectionConfig.xml
  SCRIPT
end

bash 'configureGitlabUser' do
  only_if { node['scm'] == 'gitlab' }
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
    <scope>GLOBAL</scope>
    <id>jenkins1cred</id>
    <description>Gitlab user</description>
    <username>#{node['gitlabuser']}</username>
    <password>#{node['gitlabpassword']}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
SCRIPT
end

bash 'configureGitlabToken' do
  only_if { node['scm'] == 'gitlab' }
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.dabsquared.gitlabjenkins.connection.GitLabApiTokenImpl plugin="gitlab-plugin@1.5.2">
  <scope>GLOBAL</scope>
  <id>Jazz-Gitlab-API-Cred</id>
  <description>Jazz-Gitlab-API-Cred</description>
  <apiToken>#{node['gitlabtoken']}</apiToken>
</com.dabsquared.gitlabjenkins.connection.GitLabApiTokenImpl>
EOF
SCRIPT
end

# TODO: we do this at the end, do we need it here?
service 'jenkins' do
  supports [:stop, :start, :restart]
  action [:restart]
end

# Wait a bit, Java apps don't coldboot very quickly...
execute 'waitForSecondJenkinsRestart' do
  command 'sleep 30'
end

directory "#{node['chef_root']}/jazz-core" do
  action :delete
end

git "#{node['chef_root']}/jazz-core" do
  repository node['git_repo']
  reference node['git_branch']
  depth 1
  action :sync
end

bash 'createcredentials-jenkins1' do
  only_if { node['scm'] == 'bitbucket' }
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>jenkins1cred</id>
  <description>user created on bitbucket</description>
  <username>#{node['bbuser']}</username>
  <password>#{node['bbpassword']}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
SCRIPT
end

bash 'createcredentials-jobexecutor' do
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>jobexecutor</id>
  <description>user created on bitbucket</description>
  <username>jobexec</username>
  <password>jenkinsadmin</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
SCRIPT
end

bash 'createcredentials-aws' do
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl plugin="aws-credentials@1.21">
  <scope>GLOBAL</scope>
  <id>awscreds1</id>
  <description>AWS Credentials</description>
  <accessKey>#{node['aws_access_key']}</accessKey>
  <secretKey>#{node['aws_secret_key']}</secretKey>
  <iamRoleArn></iamRoleArn>
  <iamMfaSerialNumber></iamMfaSerialNumber>
</com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl>
EOF
SCRIPT
end

bash 'createcredentials-cognitouser' do
  code <<-SCRIPT
cat <<EOF | java -jar #{node['jenkins']['clientjar']} -s http://#{node['jenkinselb']}/ -auth @#{node['authfile']} create-credentials-by-xml system::system::jenkins "(global)"
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>SVC_ADMIN</id>
  <description>Jazz Admin User</description>
  <username>#{node['cognitouser']}</username>
  <password>#{node['cognitopassword']}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
SCRIPT
end

bash 'configJenkinsLocConfigXml' do
  code <<-SCRIPT
JENKINS_LOC_CONFIG_XML=/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml

sed  -i "s=adminAddress.*.$=adminAddress>#{node['jenkins']['SES-defaultSuffix']}</adminAddress>=g" $JENKINS_LOC_CONFIG_XML
sed  -i "s=jenkinsUrl.*.$=jenkinsUrl>http://#{node['jenkinselb']}/</jenkinsUrl>=g" $JENKINS_LOC_CONFIG_XML
SCRIPT
end

execute 'createJob-create-service' do
  command "#{node['script_root']}/jobs/job_create-service.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-delete-service' do
  command "#{node['script_root']}/jobs/job_delete-service.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-job_build_pack_api' do
  command "#{node['script_root']}/jobs/job_build_pack_api.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-bitbucketteam_newService' do
  only_if { node['scm'] == 'bitbucket' }
  command "#{node['script_root']}/jobs/job_bitbucketteam_newService.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-platform_api_services' do
  only_if { node['scm'] == 'bitbucket' }
  command "#{node['script_root']}/jobs/job_platform_api_services.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'job_cleanup_cloudfront_distributions' do
  command "#{node['script_root']}/jobs/job_cleanup_cloudfront_distributions.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-job-pack-lambda' do
  command "#{node['script_root']}/jobs/job_build_pack_lambda.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-job-build-pack-website' do
  command "#{node['script_root']}/jobs/job_build_pack_website.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'job-gitlab-trigger' do
  only_if { node['scm'] == 'gitlab' }
  command "#{node['script_root']}/jobs/job-gitlab-trigger.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

execute 'createJob-jazz_ui' do
  only_if { node['scm'] == 'gitlab' }
  command "#{node['script_root']}/jobs/job_jazz_ui.sh #{node['jenkinselb']} #{node['jenkins']['clientjar']} #{node['authfile']} #{node['scmpath']}"
end

directory '/var/lib/jenkins' do
  owner 'jenkins'
  group 'jenkins'
  action :create
end

service 'jenkins' do
  supports [:stop, :start, :restart]
  action [:restart]
end
