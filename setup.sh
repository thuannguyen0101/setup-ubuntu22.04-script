#!/bin/bash

# Kiểm tra quyền sudo và yêu cầu nhập mật khẩu nếu cần
if ! sudo -v; then
    echo "Cần quyền sudo để tiếp tục."
    exit 1
fi

# Kiểm tra xem một gói có được cài đặt hay không
is_installed() {
    dpkg -l | grep -i "$1" &>/dev/null
}

# Function để tạo progress bar
progress_bar() {
    local duration=$1
    local bar_length=50
    local progress=0

    while [ $progress -le $bar_length ]; do
        printf "\r["
        for ((i=0; i<$progress; i++)); do printf "#"; done
        for ((i=$progress; i<$bar_length; i++)); do printf " "; done
        printf "] %d%%", $((progress * 100 / bar_length))
        progress=$((progress + 1))
        sleep $((duration / bar_length))
    done
    echo ""
}

# Cài đặt các gói và dịch vụ cần thiết

## Cập nhật hệ thống
echo "Cập nhật hệ thống..."
progress_bar 5
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common curl git

## Kiểm tra và cài đặt PHP nếu chưa cài
if ! is_installed "php7.4"; then
    echo "Cài đặt PHP 7.4..."
    progress_bar 5
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install -y php7.4 php7.4-cli php7.4-fpm php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath
else
    echo "PHP 7.4 đã được cài đặt."
fi

## Kiểm tra và cài đặt Composer nếu chưa cài
if ! command -v composer &>/dev/null; then
    echo "Cài đặt Composer..."
    progress_bar 5
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    HASH=$(curl -sS https://composer.github.io/installer.sig)
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); }"
    if [ $? -ne 0 ]; then
        echo "Cài đặt Composer thất bại."
        exit 1
    fi
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
else
    echo "Composer đã được cài đặt."
fi

## Kiểm tra và cài đặt Nginx nếu chưa cài
if ! is_installed "nginx"; then
    echo "Cài đặt Nginx..."
    progress_bar 5
    sudo apt install -y nginx
else
    echo "Nginx đã được cài đặt."
fi

## Kiểm tra và cài đặt MariaDB nếu chưa cài
if ! is_installed "mariadb-server"; then
    echo "Cài đặt MariaDB..."
    progress_bar 5
    sudo apt install -y mariadb-server
    read -sp "Nhập mật khẩu mới cho tài khoản admin: " DB_PASSWORD
    echo

    SQL_COMMAND="ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD'; FLUSH PRIVILEGES;"
    echo "Đang cấu hình tài khoản admin trong MariaDB..."
    sudo mariadb -e "$SQL_COMMAND"
else
    echo "MariaDB đã được cài đặt."
fi

## Kiểm tra và cài đặt Docker nếu chưa cài
if ! command -v docker &>/dev/null; then
    echo "Cài đặt Docker..."
    progress_bar 5
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo "Docker đã được cài đặt."
fi

## Kiểm tra và cài đặt Docker Compose nếu chưa cài
if ! command -v docker-compose &>/dev/null; then
    echo "Cài đặt Docker Compose..."
    progress_bar 5
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose đã được cài đặt."
fi

## Kiểm tra và cài đặt Redis nếu chưa cài
if ! is_installed "redis-server"; then
    echo "Cài đặt Redis..."
    progress_bar 5
    sudo apt install -y redis-server
else
    echo "Redis đã được cài đặt."
fi

## Kiểm tra và cài đặt Node.js nếu chưa cài
if ! command -v node &>/dev/null; then
    echo "Cài đặt Node.js..."
    progress_bar 5
    sudo apt install -y nodejs npm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    source ~/.bashrc
else
    echo "Node.js đã được cài đặt."
fi

# Hoàn thành
echo "Setup hoàn tất! Vui lòng đăng xuất và đăng nhập lại để các quyền Docker có hiệu lực."
