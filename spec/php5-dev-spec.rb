require_relative "lib/ansible_helper"
require_relative "bootstrap"

RSpec.configure do |config|
  config.before :suite do
    AnsibleHelper.instance.playbook("playbooks/php5-playbook.yml", {
      env_name: "dev",
      copy_phpinfo: true,
      copy_index_php: true
    })

    set :env, :PHPENV_VERSION => "5.6.21"
  end
end

describe "Phpenv is installed and working" do
  include_examples "phpenv"
end

describe command("php --version") do
  it "has no errors" do
    expect(subject.exit_status).to eq 0
  end

  it "is the correct version" do
    expect(subject.stdout).to match /^PHP 5\.6\.21/
  end

  it "has OPcache enabled" do
    expect(subject.stdout).to match /^\s+with Zend OPcache v\d+\.\d+\.\d+/
  end
end

describe command(%Q{php -r 'echo "PHP is running\\n";'}) do
  it "executes PHP code" do
    expect(subject.stdout).to match /^PHP is running$/
  end
end

describe command("php -i") do
  it "has BZip2 installed" do
    expect(subject.stdout).to match /^BZip2 Support => Enabled/
  end

  it "has GMP installed" do
    expect(subject.stdout).to match /^gmp support => enabled/
  end

  it "has iconv installed" do
    expect(subject.stdout).to match /^iconv support => enabled/
  end

  it "has Imagick installed" do
    expect(subject.stdout).to match /^imagick module => enabled/
  end

  it "has Intl installed" do
    expect(subject.stdout).to match /^Internationalization support => enabled/
  end

  it "has PDO MySQL installed" do
    expect(subject.stdout).to match /^PDO Driver for MySQL => enabled/
  end

  it "has PDO PostgreSQL installed" do
    expect(subject.stdout).to match /^PDO Driver for PostgreSQL => enabled/
  end

  it "has PDO SQLite installed" do
    expect(subject.stdout).to match /^PDO Driver for SQLite 3.x => enabled/
  end

  it "has PSpell installed" do
    expect(subject.stdout).to match /^PSpell Support => enabled/
  end

  it "has Redis installed" do
    expect(subject.stdout).to match /^Redis Support => enabled/
  end

  it "has XDebug installed" do
    expect(subject.stdout).to match /^xdebug support => enabled/
  end

  it "has YAML installed" do
    expect(subject.stdout).to match /^LibYAML Support => enabled/
  end

  it "does not have Tidy installed" do
    expect(subject.stdout).to_not match /^Tidy support => enabled/
  end

  it "has the default timezone set" do
    expect(subject.stdout).to match /^Default timezone => Etc\/UTC/
  end

  it "has the max upload size set" do
    expect(subject.stdout).to match /upload_max_filesize => 10M/
  end

  it "has the environment name set" do
    expect(subject.stdout).to match /_SERVER\["ENV_NAME"\] => dev/
  end
end

describe command("pear config-show") do
  it "has temp directories set correctly" do
    expect(subject.stdout).to match /cache_dir\s+\/tmp\/phpenv\/5\.6\.21\/pear\/cache$/
    expect(subject.stdout).to match /download_dir\s+\/tmp\/phpenv\/5\.6\.21\/pear\/download$/
    expect(subject.stdout).to match /temp_dir\s+\/tmp\/phpenv\/5\.6\.21\/pear$/
  end
end

describe command("composer") do
  it "does not have XDebug enabled" do
    expect(subject.stderr).to_not match /You are running composer with xdebug enabled/
  end
end

describe command("phpunit --version") do
  it "is installed" do
    expect(subject.stdout).to match /^PHPUnit 5\.3\.\d+/
  end
end

describe command("phpunit /srv/http/phpenv-test.dev/public/phpinfo.php") do
  it "has XDebug enabled" do
    expect(subject.stdout).to match /^xdebug support => enabled/
  end
end

describe command("psysh --version") do
  it "is installed" do
    expect(subject.stdout).to match /Psy Shell v0\.7\.\d+/
  end
end

describe command("curl -i phpenv-test.dev") do
  it "sends a 200 OK response" do
    expect(subject.stdout).to match /^HTTP\/1\.1 200 OK$/
  end

  it "executes PHP code" do
    expect(subject.stdout).to match /Nginx is serving PHP 5\.6\.21 code on phpenv-test\.dev/
  end
end

describe command("curl phpenv-test.dev/phpinfo.php") do
  it "has XDebug enabled" do
    expect(subject.stdout).to match /<th>xdebug support<\/th><th>enabled<\/th>/
  end

  it "has the environment name set" do
    expect(subject.stdout).to match /_SERVER\["ENV_NAME"\]<\/td><td.+>dev/
  end
end

describe command("curl phpenv-test.dev/disabled_functions_test.php") do
  it "has shell_exec disabled" do
    expect(subject.stdout).to match /Warning: shell_exec\(\) has been disabled for security reasons/
  end
end

describe command("curl phpenv-test.dev/open_basedir_test.php") do
  it "has open_basedir enabled" do
    expect(subject.stdout).to match /open_basedir restriction in effect\. File\(.+\) is not within the allowed path\(s\)/
  end
end

describe command("curl phpenv-test.dev/session_test.php") do
  it "can start a session" do
    expect(subject.stdout).to match /^2$/ # 2 == PHP_SESSION_ACTIVE
  end
end

describe command("curl phpenv-test.dev/error_test.php") do
  it "doesn't create any output" do
    expect(subject.stdout).to eq ''
  end
end

describe command("tail -n 1 /usr/local/phpenv/versions/5.6.21/var/log/error.log") do
  it "logged an error" do
    expect(subject.stdout).to match /Test error message$/
  end
end

describe command("curl -I phpenv-test.dev/some-url") do
  it 'does not redirect to index.php' do
    expect(subject.stdout).to match /^HTTP\/1\.1 404 Not Found$/
  end
end

describe "Nginx config is valid" do
  include_examples "nginx::config"
end
