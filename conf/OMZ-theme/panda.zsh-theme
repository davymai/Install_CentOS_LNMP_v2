# PandaMan theme for oh-my-zsh
# Link: https://xmyunwei.com

# IP地址, 使用命令ifconfig获取网口名称并修改"eth0"
#ipaddr=$(ifconfig eth0 | awk '/inet / {print $2}' | cut -f2 -d ":" | awk 'NR==1 {print $1}')

# 颜色短代码
R=$fg_no_bold[red]
G=$fg_no_bold[green]
M=$fg_no_bold[magenta]
Y=$fg_no_bold[yellow]
B=$fg_no_bold[blue]
W=$fg_no_bold[white]
RESET=$reset_color

if [ "$UID" = 0 ]; then
    PROMPTPREFIX="%{$M%}%B-!- %(?:%{$W%}%Broot:%{$W%}%Broot)"
    HOSTNAME="%{$B%}%B%m %{$M%}%B%U$ipaddr%u"
    local ret_status="%{$M%}%B» "
    DATETIME="%{$W%}%B[%{$B%}%B$(date +%Y-%-m-%-d)%{$W%}%B|%{$RESET%}%B%*%{$W%}%B]%{$M%} WARNING: Now root login !"
else
    PROMPTPREFIX="%{$RESET%}%B# %(?:%{$G%}%B${USER}:%{$G%}%B${USER})"
    HOSTNAME="%{$Y%}%B%m %{$M%}%B%U$ipaddr%u"
    local ret_status="%{$Y%}%B» "
    DATETIME="%{$W%}%B[%{$B%}%B$(date +%Y-%-m-%-d)%{$W%}%B|%{$RESET%}%B%*%{$W%}%B]"
fi

local return_code="%{$RESET%}[\
%{$Y%}%B%?\
%{$RESET%}]%{$R%}%B↵"

# 获取Git工作目录的状态
custom_git_prompt_status() {
    INDEX=$(git status --porcelain 2> /dev/null)
    STATUS=""
    # Non-staged
    if $(echo "$INDEX" | grep '^?? ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_UNTRACKED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^UU ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_UNMERGED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^ D ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^.M ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
    elif $(echo "$INDEX" | grep '^AM ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
    elif $(echo "$INDEX" | grep '^ T ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
    fi
    # Staged
    if $(echo "$INDEX" | grep '^D  ' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_DELETED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^R' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_RENAMED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^M' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_MODIFIED$STATUS"
    fi
    if $(echo "$INDEX" | grep '^A' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_ADDED$STATUS"
    fi

    if $(echo -n "$STATUS" | grep '.*' &> /dev/null); then
        STATUS="$ZSH_THEME_GIT_STATUS_PREFIX$STATUS"
    fi

    echo $STATUS
}

# 获取所在的分支名称
function custom_git_prompt() {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo "$(git_prompt_ahead)$ZSH_THEME_GIT_PROMPT_PREFIX$(custom_git_prompt_status) ${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_SUFFIX$(parse_git_dirty)"
}

# %B 设置粗体文本
PROMPT="
$DATETIME%B$PROMPTPREFIX%{$G%}%B@$HOSTNAME %{$R%}%B%~ "

PROMPT+='$(custom_git_prompt)%{$W%}%B>
${ret_status}%b%{$RESET%}'

#在行末显示上一命令的返回状态
RPROMPT="${return_code}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$Y%}%B‹%{$B%}%Bgit:%{$G%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$Y%}%B› %{$RESET%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$RESET%}%B➔➔ "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$Y%}✗✗ "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$W%}✔ "
ZSH_THEME_GIT_STATUS_PREFIX=" "

# Staged
ZSH_THEME_GIT_PROMPT_STAGED_ADDED="%{$G%}A"
ZSH_THEME_GIT_PROMPT_STAGED_MODIFIED="%{$G%}M"
SH_THEME_GIT_PROMPT_STAGED_RENAMED="%{$M%}R"
ZSH_THEME_GIT_PROMPT_STAGED_DELETED="%{$R%}D"

# Not-staged
ZSH_THEME_GIT_PROMPT_ADDED="%{$G%}A"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$R%}M"
ZSH_THEME_GIT_PROMPT_DELETED="%{$R%}D"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$M%}R"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$Y%}UU"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$R%}✭"
