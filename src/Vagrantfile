# -*- mode: ruby -*-
# vi: set ft=ruby :

# Use this Vagrant configuration file for local installation of the Oro application.
# Please, refer to the Oro Applications installation guides for the detailed instructions:
# https://doc.oroinc.com/backend/setup/dev-environment/vagrant/

Vagrant.require_version ">= 2.3"
oro_baseline_version = ( ENV['ORO_BASELINE_VERSION'] || '5.1-latest').to_s
oro_test = ( ENV['ORO_TEST'] || 'no-test').to_s
memory = ( ENV['MEMORY'] || 8192 ).to_i
cpus = ( ENV['CPUS'] || 4 ).to_i

licence = (ENV['licence']).to_s
gittoken = (ENV['gittoken']).to_s

if ARGV[0] == "up" || ARGV[0] == "provision"
    if !licence || licence.empty?
        puts "You must provide your Enterprise Licence Key to be able to install Oro Enterprise Edition application before 'vagrant up' command (licence=YourEnterpsiseLicenceKey gittoken=yourgithubtoken vagrant up --provision)"
        abort
    end
    if !gittoken || gittoken.empty?
        puts "You must provide your GitHub Token to be able to install Oro Enterprise Edition application before 'vagrant up' command (licence=YourEnterpsiseLicenceKey gittoken=yourgithubtoken vagrant up --provision)"
        abort
    end
end

$scriptInstallBaseSystem = <<-'SCRIPT'
    set -xe
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    setenforce permissive
    systemctl disable --now firewalld

    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf config-manager --save --setopt="docker-ce-*.priority=1"
    dnf -y upgrade
    dnf -y install git-core bzip2 unzip bc psmisc wget jq docker-ce docker-compose-plugin docker-buildx-plugin
    usermod -aG docker vagrant
    systemctl enable --now "docker.service"
SCRIPT

$scriptBuild = <<-'SCRIPT'
    export COMPOSER_PROCESS_TIMEOUT=600
    if [[ "X$GITHUB_TOKEN" != 'X' ]]; then
        COMPOSER_AUTH="{\"github-oauth\": {\"github.com\": \"$GITHUB_TOKEN\"}}"
        export COMPOSER_AUTH
    fi
    set -xe
    # Prepare repositories
    rm -rf /srv/docker-build ||:
    git clone https://github.com/oroinc/docker-build /srv/docker-build
    if [[ "X$LICENCE_KEY" != 'X' ]]; then
        echo "ORO_ENTERPRISE_LICENCE=$LICENCE_KEY" >> "/srv/docker-build/docker-compose/.env"
    fi
    # set port for WS
    echo 'ORO_WEBSOCKET_FRONTEND_DSN=//*:8000/ws' >> "/srv/docker-build/docker-compose/.env"
    export ORO_PROJECT=''
    rm -rf /srv/vagrant ||:
    cp -rf /vagrant /srv/ ||:
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    /srv/docker-build/scripts/composer.sh -b ${ORO_BASELINE_VERSION} -s /srv/vagrant -p 'redis oro_multi_host.enabled=true multi_host_operation_directory="%env(ORO_MULTIHOST_OPERATION_FOLDER)%"' -- '--no-dev install'
    docker buildx build --pull --load --rm --build-arg ORO_BASELINE_VERSION -t ${ORO_IMAGE,,}:$ORO_IMAGE_TAG -f "/srv/docker-build/docker/Dockerfile" /srv/vagrant
    docker image prune -f
    rm -rf /srv/vagrant ||:
SCRIPT

$scriptBuildTest = <<-'SCRIPT'
    export COMPOSER_PROCESS_TIMEOUT=600
    if [[ "X$GITHUB_TOKEN" != 'X' ]]; then
        COMPOSER_AUTH="{\"github-oauth\": {\"github.com\": \"$GITHUB_TOKEN\"}}"
        export COMPOSER_AUTH
    fi
    set -xe
    # Prepare repositories
    rm -rf /srv/docker-build ||:
    git clone https://github.com/oroinc/docker-build /srv/docker-build
    if [[ "X$LICENCE_KEY" != 'X' ]]; then
        echo "ORO_ENTERPRISE_LICENCE=$LICENCE_KEY" >> "/srv/docker-build/docker-compose/.env"
    fi
    # set port for WS
    echo 'ORO_WEBSOCKET_FRONTEND_DSN=//*:8000/ws' >> "/srv/docker-build/docker-compose/.env"
    echo "ORO_ENV=test" >> "/srv/docker-build/docker-compose/.env"
    export ORO_PROJECT=''
    rm -rf /srv/vagrant ||:
    cp -rf /vagrant /srv/ ||:
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    /srv/docker-build/scripts/composer.sh -b ${ORO_BASELINE_VERSION} -s /srv/vagrant -p 'redis oro_multi_host.enabled=true multi_host_operation_directory="%env(ORO_MULTIHOST_OPERATION_FOLDER)%"'
    docker buildx build --pull --load --rm --build-arg ORO_BASELINE_VERSION -t ${ORO_IMAGE_TEST,,}:$ORO_IMAGE_TAG -f "/srv/docker-build/docker/Dockerfile-test" /srv/vagrant
    docker image prune -f
    rm -rf /srv/vagrant ||:
SCRIPT

$scriptInstall = <<-'SCRIPT'
    export ORO_PROJECT=''
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    set -xe
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" down -v
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" pull --ignore-pull-failures --quiet --include-deps install
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --pull never --exit-code-from install --attach install install
    rm -rf "/srv/docker-build/docker/public_storage" ||:
    rm -rf "/srv/docker-build/docker/private_storage" ||:
    docker cp docker-compose-install-1:/var/www/oro/public/media/ "/srv/docker-build/docker/public_storage"
    docker cp docker-compose-install-1:/var/www/oro/var/data/ "/srv/docker-build/docker/private_storage"
    CACHEBUST=$(uuidgen) DB_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' docker-compose-db-1) docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" --progress plain build backup
    rm -rf "/srv/docker-build/docker/public_storage" ||:
    rm -rf "/srv/docker-build/docker/private_storage" ||:
SCRIPT

$scriptInstallTest = <<-'SCRIPT'
    export ORO_PROJECT=''
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    set -xe
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" down -v
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" pull --ignore-pull-failures --quiet --include-deps install-test
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --pull never --exit-code-from install-test --attach install-test install-test
    rm -rf "/srv/docker-build/docker/public_storage" ||:
    rm -rf "/srv/docker-build/docker/private_storage" ||:
    docker cp docker-compose-install-test-1:/var/www/oro/public/media/ "/srv/docker-build/docker/public_storage"
    docker cp docker-compose-install-test-1:/var/www/oro/var/data/ "/srv/docker-build/docker/private_storage"
    CACHEBUST=$(uuidgen) DB_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' docker-compose-db-1) docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" --progress plain build backup-test
    rm -rf "/srv/docker-build/docker/public_storage" ||:
    rm -rf "/srv/docker-build/docker/private_storage" ||:
SCRIPT

$scriptRunTestFunctional = <<-'SCRIPT'
    export ORO_PROJECT=''
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    set -xe
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" down -v
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --quiet-pull --exit-code-from restore-test --attach restore-test restore-test
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --quiet-pull --exit-code-from functional --attach functional functional
SCRIPT

$scriptRunTestBehat = <<-'SCRIPT'
    export ORO_PROJECT=''
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    set -xe
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" down -v
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --quiet-pull --exit-code-from restore --attach restore restore
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --quiet-pull --exit-code-from behat --attach behat behat
SCRIPT

$scriptDeploy = <<-'SCRIPT'
    export ORO_PROJECT=''
    set -o allexport
    source "/vagrant/.env-build"
    set +o allexport
    export ORO_IMAGE_TAG=local
    set -xe
    docker compose --project-directory "/srv/docker-build/docker-compose" -f "/srv/docker-build/docker-compose/compose-orocommerce-application.yaml" -f "/srv/docker-build/docker-compose/compose_ee_services.yaml" up --attach application application
    set +x
    echo '***********************************************************************************************************************'
    echo '************* Congratulations! You’ve Successfully Installed OroCommerce Application **********************************'
    echo '***********************************************************************************************************************'
    echo '************* You should now be able to open the homepage http://localhost.dev.oroinc.com:8000 and use the application.'
    echo '***********************************************************************************************************************'
SCRIPT

Vagrant.configure(2) do |config|
    config.vagrant.plugins = ["vagrant-env"]
    config.env.enable # Enable vagrant-env(.env)
    config.vm.hostname = "orodev"
    config.vm.network "forwarded_port", guest: 80, host: 8000
    config.vm.provider :virtualbox do |vb, override|
        override.vm.box_url = "https://oracle.github.io/vagrant-projects/boxes/oraclelinux/8-btrfs.json"
        override.vm.box = "oraclelinux/8-btrfs"
        vb.gui = false
        vb.memory = memory
        vb.cpus = cpus
    end

    config.vm.provision "InstallBaseSystem", type: "shell" do |s|
        s.inline= $scriptInstallBaseSystem
        s.env = {LICENCE_KEY:licence, GITHUB_TOKEN:gittoken, ORO_BASELINE_VERSION:oro_baseline_version}
        s.sensitive = true
    end

    # if you would like create application test image, install application in dev environment and run functional tests set variable ORO_TEST=functional
    if oro_test == "functional" || oro_test == "behat"
        if oro_test == "functional"
            config.vm.provision "BuildTest", type: "shell" do |s|
                s.inline = $scriptBuildTest
                s.env = {LICENCE_KEY:licence, GITHUB_TOKEN:gittoken, ORO_BASELINE_VERSION:oro_baseline_version}
                s.sensitive = true
            end        
            config.vm.provision "InstallTest", type: "shell", inline: $scriptInstallTest
            config.vm.provision "RunTestFunctional", type: "shell" do |s|
                s.inline = $scriptRunTestFunctional
                s.env = {ORO_FUNCTIONAL_ARGS:(ENV['ORO_FUNCTIONAL_ARGS'] || ' ').to_s}
            end
        elsif oro_test == "behat"
            config.vm.provision "BuildTest", type: "shell" do |s|
                s.inline = $scriptBuildTest
                s.env = {LICENCE_KEY:licence, GITHUB_TOKEN:gittoken, ORO_BASELINE_VERSION:oro_baseline_version}
                s.sensitive = true
            end        
            config.vm.provision "Build", type: "shell" do |s|
                s.inline = $scriptBuild
                s.env = {LICENCE_KEY:licence, GITHUB_TOKEN:gittoken, ORO_BASELINE_VERSION:oro_baseline_version}
                s.sensitive = true
            end
            config.vm.provision "Install", type: "shell", inline: $scriptInstall
            config.vm.provision "RunTestBehat", type: "shell" do |s|
                s.inline = $scriptRunTestBehat
                s.env = {ORO_BEHAT_ARGS:(ENV['ORO_BEHAT_ARGS'] || ' ').to_s, ORO_BEHAT_OPTIONS:(ENV['ORO_BEHAT_OPTIONS'] || '--skip-isolators --tags=smoke&&~@skip ').to_s}
            end
        end
    else
        config.vm.provision "Build", type: "shell" do |s|
            s.inline = $scriptBuild
            s.env = {LICENCE_KEY:licence, GITHUB_TOKEN:gittoken, ORO_BASELINE_VERSION:oro_baseline_version}
            s.sensitive = true
        end
        config.vm.provision "Install", type: "shell", inline: $scriptInstall
        config.vm.provision "Deploy", type: "shell", inline: $scriptDeploy
    end
end

