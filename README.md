TRAC-GIT-HOOKS
==============

A script that I've made that install apache2, trac 0.12(with i18n), git, gitolite and configures them to work in a Ubuntu 12.04 server.

REQUIREMENTS
=============
This was tested in a Ubuntu 12.04 Server 64bits in 08/2012.

Root access to the server or similar.

You'll also need to have a working station(another computer besides the server)

You'll have to copy this working station pub rsa key to somewhere in the server, ex::

    scp ~/.ssh/id_rsa.pub root@192.168.0.108:/tmp/myNewUser.pub

Where my myNewUser must be the name of the user name you want to create.

USAGE
=============
You can just download this scripts into anywhere, like /tmp/ in the server::

    wget https://github.com/arruda/TRAC-GIT-HOOKS/tarball/master
    tar -zxvf master

 and then run the first script::

    ./install_1.sh PROJECT_NAME REPO_NAME DOMAIN_NAME USER_NAME USER_PSSWD RSA_FOLDER_PATH

Where:
-----------------------------------
PROJECT_NAME: is the name of your project, ex: MyTrac

REPO_NAME:  is the name of your repository, ex: mynewrepo

DOMAIN_NAME: your domain, ex: mysite.com

USER_NAME: your username, ex: myNewUser (THIS MUST BE THE SAME USER NAME OF THE RSA KEY BEFORE!)

USER_PSSWD: your password, ex: mystrongpass

RSA_FOLDER_PATH: the path to the folder where you put the rsa pub key, ex: /tmp


Exemple of usage::

    ./install_1.sh MyTrac mynewrepo mysite.com myNewUser mystrongpass /tmp

Afther this is done, you'll need to go to your workstation and do the following:

Back in the workstation(the one that you copied the id_rsa.pub)::

    git clone git@DOMAIN_NAME:gitolite-admin

replacing DOMAIN_NAME with your server domain.

Open the conf/gitolite.conf file, and add this lines to the end of it::

    repo REPO_NAME
        RW+    =    USER_NAME

replacing REPO_NAME and USER_NAME with the ones used in the execution of the script.
    
save, commit and push it::

    git add . 
    git commit -m 'new repo' 
    git push origin master

After this execute install_2.sh, using the same parameters as before! Ex::

    ./install_2.sh MyTrac mynewrepo mysite.com myNewUser mystrongpass /tmp



LICENSE
=============
This software is distributed using MIT license, see LICENSE file for more details.
