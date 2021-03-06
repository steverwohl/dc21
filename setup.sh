source setup_config

type -P expect > /dev/null
if [ $? -ne 0 ]; then
  sudo yum install -y expect
fi

wget https://github.com/steverwohl/dc21/blob/master/vm_setup.sh?raw=true -O vm_setup.sh --no-check-certificate
/usr/bin/expect -<<EOD
set timeout -1
set already_confirmed_password 0

spawn bash vm_setup.sh

expect {
    "password for $USER:" { send "$PASSWORD\r" ; exp_continue}

    "Password: <hidden>" {send ""; exp_continue}

    "Password: " {send "$PASSWORD\r" ; exp_continue}

    "New jOAI password (at least six alphanumeric characters):" {send "$JOAI\r"; exp_continue}

    "First name:" {send "$FIRST_NAME\r" ; exp_continue}

    "Last name:" {send "$LAST_NAME\r" ; exp_continue}

    "Email:" {send "$EMAIL\r" ; exp_continue}

    "New user password (input will be hidden): " {send "$USER_PASS\r" ; exp_continue}

    "Confirm password: " {
        if {\$already_confirmed_password == 0} {
            set already_confirmed_password 1
            send "$JOAI\r" ; exp_continue
        } else {
            send "$USER_PASS\r" ; exp_continue
        }
    }

    "Tag to deploy (make sure to push the branch/tag first) or HEAD?: " { send "$DC21_TAG\r" ; exp_continue}

    "Is this okay?" {send "yes\r" ; exp_continue}

    "Country Name (2 letter code)" {send "$SSL_COUNTRY_CODE\r" ; exp_continue}

    "State or Province Name (full name)" {send "$SSL_STATE_CODE\r" ; exp_continue}

    "Locality Name (eg, city)" {send "$SSL_CITY\r" ; exp_continue}

    "Organization Name (eg, company)" {send "$SSL_ORGANIZATION_NAME\r" ; exp_continue}

    "Organizational Unit Name (eg, section)" {send "$SSL_ORGANIZATION_UNIT_NAME\r" ; exp_continue}

    "Common Name (eg, your name or your server's hostname)" {send "$DC21_HOST\r" ; exp_continue}

    "Email Address" {send "$SSL_EMAIL\r" ; exp_continue}

    "There are pending migrations. Are you sure you want to continue?" {send "yes\r" ; exp_continue}

}

EOD
