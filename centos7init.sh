#!/bin/bash
#################################################
#  --Info
#      Panda Initialization CentOS 7.x script
#################################################
#   File: centos7-init.sh
#
#   Usage: sh centos7-init.sh
#
#   Auther: PandaMan ( i[at]davymai.com )
#
#   Link: https://xmyunwei.com
#
#   Version: 3.0
#################################################
# set parameter
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear

function INFO() {
    echo -e "\e[$1;49;1m $3 \033[39;49;0m"
    sleep "$2"
    echo ""
}
#安装目录
ENV_PATH="/usr/local"
#源码包存放目录
SOURCE_PATH="$(cd $(dirname -- $0)
pwd)/install_tar"
#LNMP配置文件的目录
CONF_PATH="$(cd $(dirname -- $0)
pwd)/conf"
#逻辑CPU个数
THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)

printf "
 +------------------------------------------------------------------------+
 |                      熊猫 CentOS 7.x 初始化脚本                        |
 |       To initialization the system for security and performance        |
 |                     初始化系统以提高安全性和性能                       |
 +------------------------------------------------------------------------+
                           version: 3.0
                      updated date: 2020-10-31

        Initialization begin after \e[31;1m5 \e[32;0mseconds, press Ctrl C to cancel.
                 初始化脚本 \e[31;1m5 \e[32;0m秒后开始, 按 ctrl C 取消。
"
echo ""

# Check if user is root
if [ $(id -u) != "0" ]; then
    INFO 31 1 "Error: You must be root to run this script, please use root to initialization OS.\n 错误：您必须是 root 用户才能运行此脚本，请使用 root 用户身份来初始化操作系统。"
    exit 1
fi
sleep 5

# start Time
startTime=$(date +%s)

# delete useless user and group
user_del() {
    INFO 35 2 "Delete useless user\n 删除无用的用户和组"
    userdel -r adm
    userdel -r lp
    userdel -r games
    userdel -r ftp
    groupdel adm
    groupdel lp
    groupdel games
    groupdel video
    groupdel ftp
    echo ""
    INFO 36 2 "Delete useless user is successful..."
}

# update system & install pakeage
config_nameserver() {
    nameserver=$(grep nameserver /etc/resolv.conf | wc -l)
    if [ $nameserver -ge 1 ]; then
        INFO 31 2 "nameserver is exist."
    else
        INFO 32 2 "add nameserver in /etc/resolv.conf"
        echo "nameserver 223.5.5.5" >> /etc/resolv.conf
        INFO 36 2 "nameserver config complete."
    fi
}

# Set timezone synchronization
timezone_config() {
    INFO 35 2 "Setting timezone..."
    /usr/bin/timedatectl | grep "Asia/Shanghai"
    if [ $? -eq 0 ]; then
        INFO 33 1 "System timezone is Asia/Shanghai."
    else
        timedatectl set-local-rtc 0 && timedatectl set-timezone Asia/Shanghai
    fi
    # config chrony
    #yum -y install chrony
    #sed -i '/server 3.centos.pool.ntp.org iburst/a\\server ntp1.aliyun.com iburst\nserver ntp2.aliyun.com iburst\nserver ntp3.aliyun.com iburst\nserver ntp4.aliyun.com iburst\nserver ntp5.aliyun.com iburst\nserver ntp6.aliyun.com iburst\nserver ntp7.aliyun.com iburst' /etc/chrony.conf
    #systemctl enable chronyd.service && systemctl start chronyd.service
    INFO 36 2 "Setting timezone && Sync network time complete."
}

system_update() {
    INFO 35 2 "*** Starting update system && install tools pakeage... ***\n        *** 正在启动更新系统 && 安装工具包... ***"
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum -y upgrade
    command -v lsb_release > /dev/null 2>&1 || {
        [ -e "/etc/euleros-release" ] && yum -y install euleros-lsb || yum -y install redhat-lsb-core
    }
    command -v gcc > /dev/null 2>&1 || yum -y install gcc
    # install openssh-server openssh-clients
    yum -y install openssh-server openssh-clients
    # install vim authconfig libselinux-utils initscripts net-tools
    yum install -y vim authconfig libselinux-utils initscripts net-tools
    rm -rf /var/cache/yum/*
    [ $? -eq 0 ] && INFO 36 2 "System upgrade && install pakeages complete.\n 系统升级和程序安装完成。"
}

# OpenSSL
Install_openSSL() {
    INFO 32 2 "Install OpenSSL"
    if [ -e "${ENV_PATH}/openssl/lib/libssl.a" ]; then
        INFO 31 1 "OpenSSL is already installed!"
    else
        # del openssl
        [ -e "/usr/bin/openssl" ] && rm -rf /usr/bin/openssl
        [ -e "/usr/local/bin/openssl" ] && rm -rf /usr/local/bin/openssl
        [ -e "/usr/local/include/openssl" ] && rm -rf /usr/local/include/openssl
        pushd ${SOURCE_PATH} > /dev/null
        tar -zxvf ${SOURCE_PATH}/openssl-1.1.1i.tar.gz
        pushd openssl-1.1.1i > /dev/null
        make clean > /dev/null
        ./config -Wl,-rpath=${ENV_PATH}/openssl/lib -fPIC --prefix=${ENV_PATH}/openssl --openssldir=${ENV_PATH}/openssl &&
        make depend
        make -j ${THREAD} && make install
        ln -s ${ENV_PATH}/openssl/bin/openssl /usr/bin/openssl &&
        ln -s ${ENV_PATH}/openssl/include/openssl /usr/include/openssl &&
        ln -s ${ENV_PATH}/openssl/lib/libssl.so.1.1 /usr/lib64/libssl.so.1.1 &&
        ln -s ${ENV_PATH}/openssl/lib/libcrypto.so.1.1 /usr/lib64/libcrypto.so.1.1 &&
        if [ -f "${ENV_PATH}/openssl/lib/libcrypto.a" ]; then
            INFO 33 2 "OpenSSL installed successfully!......"
            rm -rf ${SOURCE_PATH}/openssl-1.1.1i
        else
            INFO 31 2 "OpenSSL install failed, Please contact the author!" && lsb_release -a
            kill -9 $$
        fi
        popd > /dev/null
    fi
}

# axel 替代wget
Install_axel() {
    INFO 32 2 "Install axel"
    if [ -e "/usr/bin/axel" ]; then
        INFO 31 1 "axel is already installed."
    else
        yum -y install openssl-devel
        pushd ${SOURCE_PATH} > /dev/null
        tar -zxvf ${SOURCE_PATH}/axel-2.17.10.tar.gz
        pushd axel-2.17.10 > /dev/null
        make clean > /dev/null
        ./configure --bindir=/usr/bin --sbindir=/usr/sbin
        make depend
        make -j ${THREAD} && make install
        grep 'alias axel="axel -a"' /etc/bashrc > /dev/null
        if [ $? -ne 0 ]; then
            sed -i '$ a\alias axel="axel -a"' /etc/bashrc
            sed -i '$ a\alias wget="axel"' /etc/bashrc
        fi
        if [ -f "/usr/bin/axel" ]; then
            INFO 33 1 "axel installed successfully!......"
            rm -rf ${SOURCE_PATH}/axel-2.17.9
        else
            INFO 31 1 "axel install failed, Please contact the author!" && lsb_release -a
            kill -9 $$
        fi
        popd > /dev/null
    fi
}

# disable selinux
selinux_config() {
    if [ -e "/etc/selinux/config" ]; then
        INFO 31 2 "selinux not installed."
    else
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
        INFO 36 2 "Dsiable selinux complete."
    fi
}

# ulimit comfig
ulimit_config() {
    INFO 35 2 "Starting config ulimit..."
    if [ ! -z "$(grep ^ulimit /etc/rc.local)" -a "$(grep ^ulimit /etc/rc.local | awk '{print $3}' | head -1)" != '655360' ]; then
        sed -i 's@^ulimit.*@ulimit -SHn 655360@' /etc/rc.local
    else
        sed -i '$ a\ulimit -SHn 655360' /etc/rc.local
    fi
    cat > /etc/security/limits.conf << EOF
* soft nproc 102400
* hard nproc 102400
* soft nofile 102400
* hard nofile 102400
EOF
    ulimit -n 102400
    [ $? -eq 0 ] && INFO 36 2 "Ulimit config complete!"
}

#set bashrc
bashrc_config() {
    INFO 35 2 "Starting bashrc config..."
    cp -f /etc/bashrc /etc/bashrc-bak
    echo "export PS1='\[\e[37;1m\][\[\e[35;49;1m\]\u\[\e[32;1m\]@\[\e[34;1m\]\h \[\e[37;1m\]➜ \[\e[31;1m\]\w \[\e[33;1m\]\t\[\e[37;1m\]]\[\e[32;1m\]$\[\e[m\] '" >> /etc/bashrc
    sed -i '$ a\set -o vi\nalias vi="vim"\nalias ll="ls -ahlF --color=auto --time-style=long-iso"\nalias ls="ls --color=auto --time-style=long-iso"\nalias grep="grep --color=auto"\nalias fgrep="fgrep --color=auto"\nalias egrep="egrep --color=auto"' /etc/bashrc
    INFO 36 2 "bashrc set OK!! 系统变量设在完成！！"
}

# install zsh & oh-my-zsh
Install_zsh() {
    ZSH_CUSTOM="/etc/oh-my-zsh/custom"
    INFO 35 2 "Starting install zsh..."
    if [ $(rpm -qa | grep zsh | wc -l) -ne 0 ]; then
        INFO 31 1 "zsh already installed..."
    else
        yum -y install gcc perl-ExtUtils-MakeMaker ncurses-devel &&
        pushd ${SOURCE_PATH} > /dev/null
        tar zxvf ${SOURCE_PATH}/zsh-5.8.tar.gz
        pushd zsh-5.8 > /dev/null
        make clean > /dev/null
        ./configure --exec-prefix=/usr
        make depend
        make -j ${THREAD} && make install
        if [ -f "/bin/zsh" ]; then
            echo "/bin/zsh" >> /etc/shells &&
            rm -rf ${SOURCE_PATH}/zsh-5.8 &&
            usermod -s /bin/zsh $(whoami) &&
            INFO 33 1 "zsh installed successfully!......"
        else
            INFO 31 1 "zsh install failed, Please contact the author!" && lsb_release -a
            kill -9 $$
        fi
        popd >/dev/null
    fi
    INFO 35 2 "Starting install oh-my-zsh..."
    if [ ! -d /etc/oh-my-zsh ]; then
        git clone https://gitee.com/mirrors/oh-my-zsh.git /etc/oh-my-zsh &&
        cp -f /etc/zshrc /etc/zshrc-bak
        cp /etc/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc &&
        pushd $ZSH_CUSTOM/plugins >/dev/null&&
        cp ${CONF_PATH}/OMZ-theme/pandaman.zsh-theme $ZSH_CUSTOM/themes/pandaman.zsh-theme &&
        git clone https://gitee.com/pankla/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting &&
        git clone https://gitee.com/pankla/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions &&
        INFO 36 2 "oh-my-zsh installation is successful..."
        INFO 32 2 "Starting config oh-my-zsh..."
        sed -ie 's|$HOME/.oh-my-zsh|/etc/oh-my-zsh|g' /etc/skel/.zshrc &&
        mkdir -p /etc/skel/.oh-my-zsh/cache &&
        echo "export ZSH_CACHE_DIR=~/.oh-my-zsh/cache" >> /etc/skel/.zshrc &&
        sed -i '/^ZSH_THEME/s/ZSH_THEME="robbyrussell"/ZSH_THEME="pandaman"/g' /etc/skel/.zshrc
        sed -i "/^plugins/s/plugins=(git)/#plugins=(git)/g" /etc/skel/.zshrc
        sed -i '$ a#alias ll="ls -halF"\nalias la="ls -AF"\nalias ls="ls -CF"\nalias l="ls -CF"\nalias grep="grep --color=auto"\n#启用命令纠错功能\n# Uncomment the following line to enable command auto-correction.\nENABLE_CORRECTION="true"\n#enables colorin the terminal bash shell export\nexport CLICOLOR=1\n#setsup thecolor scheme for list export\nexport LSCOLORS=ExfxcxdxBxegedabagacad\n#开启颜色\nautoload -U colors && colors\n#zsh-syntax-highlighting\nexport ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/highlighters\nsource $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n#zsh-autosuggestions\nsource $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\n#oh-my-zsh插件\nplugins=(git z extract sublime autojump zsh-syntax-highlighting zsh-autosuggestions)\n[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh\n\nsource /etc/profile' /etc/skel/.zshrc
        INFO 36 2 "oh-my-zsh configuration is successful..."
    else
        INFO 31 1 "oh-my-zsh already installed..."
    fi
}

# sshd config
sshd_config() {
    INFO 35 2 "Starting config sshd..."
    sed -i '/^#Port/s/#Port 22/Port '$sshp'/g' /etc/ssh/sshd_config
    sed -i '/^#UseDNS/s/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    sed -i "s/UsePAM.*/UsePAM yes/g" /etc/ssh/sshd_config
    sed -i '/^GSSAPIAuthentication/s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    #if you do not want to allow root login,please open below
    #sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    [ $? -eq 0 ] && INFO 36 2 "SSH port $sshp config complete."
}

# firewalld config
config_firewalld() {
    INFO 35 2 "Starting config firewalld..."
    rpm -qa | grep firewalld >> /dev/null
    if [ $? -eq 0 ]; then
        #systemctl stop firewalld && systemctl disable firewalld
        firewall-cmd --permanent --add-port=$sshp/tcp
        firewall-cmd --rel
        firewall-cmd --list-all
        [ $? -eq 0 ] && INFO 36 2 "Config firewalld complete."
    else
        INFO 35 2 "Firewalld not install."
    fi
}

# vim config
vim_config() {
    INFO 35 2 "Starting vim config..."
    /usr/bin/egrep pastetoggle /etc/vimrc >> /dev/null
    if [ $? -eq 0 ]; then
        INFO 35 2 "vim already config"
    else
        sed -i '$ a\set pastetoggle=<F9>\nsyntax on\nset nu!\nset tabstop=4\nset softtabstop=4\nset shiftwidth=4\nset expandtab\nset bg=dark\nset ruler\ncolorscheme ron' /etc/vimrc
        INFO 36 2 "vim configuration is successful..."
    fi
}

# sysctl config
config_sysctl() {
    INFO 35 2 "Staring config sysctl..."
    cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
    cat /dev/null > /etc/sysctl.conf
    cat > /etc/sysctl.conf << EOF
fs.file-max = 655350
vm.swappiness = 0
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
fs.suid_dumpable = 0
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 262144
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
# 开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
# timewait的数量，默认18000
net.ipv4.tcp_max_tw_buckets = 8000
net.ipv4.tcp_fin_timeout = 30
# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 600
# 开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
EOF
    INFO 36 2 "sysctl config complete."
}

# ipv6 config
disable_ipv6() {
    INFO 35 2 "Starting disable ipv6..."
    sed -i '$ a\net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
    sed -i '$ a\AddressFamily inet' /etc/ssh/sshd_config
    systemctl restart sshd
    /usr/sbin/sysctl -p
    sleep 3
    INFO 36 2 "disable ipv6 complete."
}

# password config
password_config() {
    INFO 35 2 "Starting config password rule"
    # /etc/login.defs  /etc/security/pwquality.conf
    sed -i '/PASS_MIN_LEN/s/5/8/g' /etc/login.defs
    #at least 8 character
    authconfig --passminlen=8 --update
    #at least 2 kinds of Character class
    authconfig --passminclass=2 --update
    #at least 1 Lowercase letter
    authconfig --enablereqlower --update
    #at least 1 Capital letter
    authconfig --enablerequpper --update
    INFO 36 2 "Config password rule complete."
}

# disable no use service
disable_serivces() {
    INFO 35 2 "Disable postfix service"
    systemctl stop postfix && systemctl disable postfix
    INFO 36 2 "Disable postfix service complete."
}

#Create OPS user
user_create() {
    INFO 35 2 "Create User\n 创建用户"
    read -p "输入用户名：" name
    read -p "输入密码：" -s -r passwd
    read -p "输入您的公钥：" rsa
    read -p "输入ssh端口号：" sshp
    useradd -G wheel $name && echo $Password | passwd --stdin $name &> /dev/null
    cd /home/$name && mkdir .ssh && chown $name:$name .ssh && chmod 700 .ssh && cd .ssh
    echo "$rsa" >> authorized_keys && chown $name:$name authorized_keys && chmod 600 authorized_keys
    usermod -s /bin/zsh $name
    echo "$name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    history -cw
    sleep 3
    echo ""
    INFO 36 2 "OPS-User: \e[33;1m$name \e[36;1mcreate is successful..."
    echo ""
}

other() {
    # Record command
    # lock user when enter wrong password root 10s others 180s
    sed -i '1aauth       required     pam_tally2.so deny=3 unlock_time=180 even_deny_root root_unlock_time=10' /etc/pam.d/sshd
    yum clean all
    sleep 3
}

#main function
main() {
    user_del
    config_nameserver
    timezone_config
    system_update
    Install_openSSL
    Install_axel
    selinux_config
    ulimit_config
    bashrc_config
    Install_zsh
    vim_config
    config_sysctl
    disable_ipv6
    password_config
    disable_serivces
    user_create
    sshd_config
    config_firewalld
    other
}
# execute main functions
main

endTime=$(date +%s)
((installTime = (endTime - startTime) / 60))
printf "
 Total initialization Install Time: \e[35;1m${installTime} \e[32;0mminutes
 +------------------------------------------------------------------------+
 |               To initialization system all completed !                 |
 |                        系统初始化全部完成 ！                           |
 +------------------------------------------------------------------------+
"
ipadd=$(ifconfig eth0 | awk '/inet/ {print $2}' | cut -f2 -d ":" | awk 'NR==1 {print $1}')
INFO 32 1 "Initialization is complete, please \e[31;1mreboot \e[32;1mthe system!!\n 系统初始化完成，请确认无误之后执行 \e[31;1mreboot \e[32;1m重启系统！\n================================\nssh端口号：\e[33;1m$sshp\n\e[32;1m服务器IP：\e[33;1m$ipadd\n\e[32;1m用户名：\e[33;1m$name\n\e[32;1m密码：\e[33;1m$passwd\n\e[32;1m请牢记您的密码!!!\n================================\n远程访问：\e[33;1mssh -p $sshp -i ~/.ssh/私钥文件 $name@$ipadd"
cat /dev/null > ~/.zsh_history
cat /dev/null > ~/.bash_history && history -c