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
function INFO() {
    echo -e "\e[$1;49;1m $3 \033[39;49;0m"
    sleep "$2"
    echo ""
}

ipadd=$(ifconfig eth0 | awk '/inet/ {print $2}' | cut -f2 -d ":" | awk 'NR==1 {print $1}')
INFO 32 1 "\n➜ 熊猫 CentOS 7.x 初始化脚本 3.0"

# Check if user is root
#
if [ $(id -u) != "0" ]; then
    INFO 31 1 "Error: You must be root to run this script, please use root to initialization OS.\n 错误：您必须是 root 用户才能运行此脚本，请使用 root 用户身份来初始化操作系统。"
    exit 1
fi

echo "+------------------------------------------------------------------------+"
echo "|       To initialization the system for security and performance        |"
echo "|                     初始化系统以提高安全性和性能                       |"
echo "+------------------------------------------------------------------------+"
echo ""
INFO 32 1 "Initialization begin after \e[31;1m5 \e[32;1mseconds, press Ctrl C to cancel.\n 初始化脚本 \e[31;1m5 \e[32;1m秒后开始，按 ctrl C 取消。"
echo ""
sleep 6

#Create Ops user
user_create() {
    #INFO 32 1 "Create User\n 创建用户"
    #read -p "输入用户名：" name
    #read -p "输入密码：" -s -r pass
    #read -p "输入您的公钥：" rsa
    read -p "输入ssh端口号：" sshp
    #useradd -G wheel $name && echo $Password | passwd --stdin $name &> /dev/null
    #cd /home/$name && mkdir .ssh && chown $name:$name .ssh && chmod 700 .ssh && cd .ssh
    #echo "$rsa" >> authorized_keys && chown $name:$name authorized_keys && chmod 600 authorized_keys
    #echo "$name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    #history -cw
    #sleep 3
    #echo ""
    #echo "Ops user: $name is created."
    #echo ""
}

# delete useless user and group
user_del() {
    INFO 32 1 "Delete useless user\n 删除无用的用户和组"
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
}

# update system & install pakeage
system_update() {
    nameserver=$(grep nameserver /etc/resolv.conf | wc -l)
    if [ $nameserver -ge 1 ]; then
        echo nameserver is exist.
    else
        echo add nameserver in /etc/resolv.conf
        echo "nameserver 114.114.114.114" >> /etc/resolv.conf
    fi
    echo ""
    echo "*** Starting update system && install tools pakeage... ***"
    echo "*** 正在启动更新系统 && 安装工具包... ***"
    yum install -y wget gcc gcc-c++ bzip2
    wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
    if [ $(rpm -qa | grep axel | wc -l) -eq 0 ]; then
        echo "axel is already installed."
    else
        cd /usr/local/src &&
            wget https://xmyunwei.com/wp-content/uploads/2020/10/axel-2.17.9.tar.bz2 &&
            tar zxvf axel-2.17.9.tar.gz &&
            cd axel-2.17.9 &&
            ./configure --bindir=/usr/bin --sbindir=/usr/sbin &&
            make -j6 && make install &&
            rm -rf /usr/local/src/*
    fi
    yum -y update
    yum -y install vim openssh-server openssh-clients authconfig iftop iotop sysstat lsof telnet traceroute tree man dstat ntpdate git
    yum clean all && rm -rf /var/cache/yum/*
    [ $? -eq 0 ] && echo "System upgrade && install pakeages complete."
    echo "系统升级和安装程序完成。" && echo ""
}

# Set timezone synchronization
timezone_config() {
    echo "Setting timezone..."
    /usr/bin/timedatectl | grep "Asia/Shanghai"
    if [ $? -eq 0 ]; then
        echo "System timezone is Asia/Shanghai."
    else
        timedatectl set-local-rtc 0 && timedatectl set-timezone Asia/Shanghai
    fi
    # config chrony
    #yum -y install chrony
    #sed -i '/server 3.centos.pool.ntp.org iburst/a\\server ntp1.aliyun.com iburst\nserver ntp2.aliyun.com iburst\nserver ntp3.aliyun.com iburst\nserver ntp4.aliyun.com iburst\nserver ntp5.aliyun.com iburst\nserver ntp6.aliyun.com iburst\nserver ntp7.aliyun.com iburst' /etc/chrony.conf
    #systemctl enable chronyd.service && systemctl start chronyd.service
    [ $? -eq 0 ] && echo "Setting timezone && Sync network time complete." && echo ""
}

# disable selinux
selinux_config() {
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    echo "Dsiable selinux complete." && echo ""
}

# ulimit comfig
ulimit_config() {
    echo "Starting config ulimit..."
    echo "ulimit -SHn 655360" >> /etc/rc.local
    cat > /etc/security/limits.conf << EOF
* soft nproc 102400
* hard nproc 102400
* soft nofile 102400
* hard nofile 102400
EOF
    ulimit -n 102400
    [ $? -eq 0 ] && echo "Ulimit config complete!" && echo ""
}

#set bashrc
bashrc_config() {
    echo "Starting bashrc config..."
    echo "export PS1='\[\e[37;1m\][\[\e[35;49;1m\]\u\[\e[32;1m\]@\\[\e[34;1m\]\h \[\e[37;1m\]➜ \[\e[31;1m\]\w \[\e[33;1m\]\t\[\e[37;1m\]]\[\e[32;1m\]\$\[\e[m\] '" >> /etc/bashrc
    sed -i '$ a\set -o vi\nalias vi="vim"\nalias ll="ls -ahlF --color=auto --time-style=long-iso"\nalias ls="ls --color=auto --time-style=long-iso"\nalias grep="grep --color=auto"\nalias fgrep="fgrep --color=auto"\nalias egrep="egrep --color=auto"' /etc/bashrc
    grep 'alias axel="axel -a"' /etc/bashrc > /dev/null
    if [ $? -ne 0 ]; then
        sed -i '$ a\alias axel="axel -a"' /etc/bashrc
    fi
    source /etc/bashrc
    echo "bashrc set OK!!"
    echo "系统变量设在完成！！"
    echo ""
    sleep 3
}

# install zsh - oh-my-zsh
install_zsh() {
    INFO 33 1.5 "Starting install zsh..."
    #LNMP配置文件的目录
    CONF_PATH="/data/lnmp/conf"
    if [ $(rpm -qa | grep zsh | wc -l) -ne 0 ]; then
        INFO 31 1.5 "zsh already installed..."
    else
        yum install -y git zsh autojump-zsh zsh-syntax-highlighting &&
            INFO 36 1.5 "zsh installation is successful..."
    fi
    INFO 33 1.5 "Starting install oh-my-zsh..."
    if [ ! -d "~/.oh-my-zsh" ]; then
        git clone https://gitee.com/mirrors/oh-my-zsh.git ~/.oh-my-zsh &&
            cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc &&
            usermod -s /bin/zsh $(whoami) &&
            #LNMP配置文件的目录
            CONF_PATH="/data/lnmp/conf"
        cp $CONF_PATH/OMZ-theme/pandaman.zsh-theme ~/.oh-my-zsh/themes/pandaman.zsh-theme &&
            cd ~/.oh-my-zsh/custom
        pwd
        git clone https://gitee.com/pankla/zsh-syntax-highlighting.git ./plugins/zsh-syntax-highlighting
        git clone https://gitee.com/pankla/zsh-autosuggestions.git ./plugins/zsh-autosuggestions &&
            INFO 36 1.5 "oh-my-zsh installation is successful..."
    else
        INFO 31 1.5 "oh-my-zsh already installed..."
    fi
}

# install zsh - oh-my-zsh
config_zsh() {
    INFO 33 1.5 "Starting config oh-my-zsh..."
    sed -i '/^ZSH_THEME/s/ZSH_THEME="robbyrussell"/ZSH_THEME="pandaman"/g' ~/.zshrc
    sed -i "/^plugins/s/plugins=(git)/#plugins=(git)/g" ~/.zshrc
    sed -i '$ a#alias ll="ls -halF"\nalias la="ls -AF"\nalias ls="ls -CF"\nalias l="ls -CF"\nalias grep="grep --color=auto"\n#启用命令纠错功能\n# Uncomment the following line to enable command auto-correction.\nENABLE_CORRECTION="true"\n#enables colorin the terminal bash shell export\nexport CLICOLOR=1\n#setsup thecolor scheme for list export\nexport LSCOLORS=ExfxcxdxBxegedabagacad\n#开启颜色\nautoload -U colors && colors\n#zsh-syntax-highlighting\nexport ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/highlighters\nsource $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n#zsh-autosuggestions\nsource $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\n#oh-my-zsh插件\nplugins=(git z extract autojump zsh-syntax-highlighting zsh-autosuggestions)\n[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh' ~/.zshrc
    INFO 36 1.5 "oh-my-zsh configuration is successful..."
}

# sshd config
sshd_config() {
    echo "Starting config sshd..."
    sed -i '/^#Port/s/#Port 22/Port '$sshp'/g' /etc/ssh/sshd_config
    sed -i '/^#UseDNS/s/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
    sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
    sed -i '/^GSSAPIAuthentication/s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    #if you do not want to allow root login,please open below
    #sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd
    sleep 3
    [ $? -eq 0 ] && echo "SSH port $sshp config complete." && echo ""
}

# firewalld config
disable_firewalld() {
    echo "Starting disable firewalld..."
    rpm -qa | grep firewalld >> /dev/null
    if [ $? -eq 0 ]; then
        systemctl stop firewalld && systemctl disable firewalld
        [ $? -eq 0 ] && echo "Disable firewalld complete." && echo ""
    else
        sleep 3
        echo "Firewalld not install." && echo ""
    fi
}

# vim config
vim_config() {
    echo "Starting vim config..."
    /usr/bin/egrep pastetoggle /etc/vimrc >> /dev/null
    if [ $? -eq 0 ]; then
        echo "" && echo "vim already config" && echo ""
    else
        #sed -i '$ a\set bg=dark\nset pastetoggle=<F9>' /etc/vimrc
        sed -i '$ a\set pastetoggle=<F9>\nsyntax on\nset nu!\nset tabstop=4\nset softtabstop=4\nset shiftwidth=4\nset expandtab\nset bg=dark\nset ruler\ncolorscheme ron' /etc/vimrc
        echo ""
    fi
    sleep 3
}

# sysctl config

config_sysctl() {
    echo "Staring config sysctl..."
    /usr/bin/cp -f /etc/sysctl.conf /etc/sysctl.conf.bak
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
# timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 8000
net.ipv4.tcp_fin_timeout = 30
# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 600
# 开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
EOF
    sleep 5
    /usr/sbin/sysctl -p
    [ $? -eq 0 ] && echo "Sysctl config complete." && echo ""
}

# ipv6 config
disable_ipv6() {
    echo "Starting disable ipv6..."
    sed -i '$ a\net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1' /etc/sysctl.conf
    sed -i '$ a\AddressFamily inet' /etc/ssh/sshd_config
    systemctl restart sshd
    /usr/sbin/sysctl -p
    sleep 3
    echo ""
}

# password config
password_config() {
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
    [ $? -eq 0 ] && echo "Config password rule complete." && echo ""
}

other() {
    # Record command
    # lock user when enter wrong password root 10s others 180s
    touch /etc/pam.d/sshd
    sed -i '1aauth       required     pam_tally2.so deny=3 unlock_time=180 even_deny_root root_unlock_time=10' /etc/pam.d/sshd
    sleep 3
}

# disable no use service
disable_serivces() {
    systemctl stop postfix && systemctl disable postfix
    sleep 3
    [ $? -eq 0 ] && echo "Disable postfix service complete."
}

#main function
main() {
    user_create
    user_del
    system_update
    timezone_config
    selinux_config
    ulimit_config
    bashrc_config
    install_zsh
    config_zsh
    sshd_config
    disable_firewalld
    vim_config
    config_sysctl
    disable_ipv6
    password_config
    disable_serivces
    other
}
# execute main functions
main
echo ""
echo "+------------------------------------------------------------------------+"
echo "|               To initialization system all completed !                 |"
echo "|                        系统初始化全部完成 ！                           |"
echo "+------------------------------------------------------------------------+"
echo ""
INFO 31 1 "Initialization is complete, please reboot the system!!"
INFO 32 1 "系统初始化完成，请确认无误之后执行 reboot 重启系统！\n================================\nssh端口号：$sshp\n服务器IP：$ipadd\n用户名：$name\n密码：$pass\n请牢记您的密码!!!\n================================\n远程访问：ssh -p $sshp $name@$ipadd"
