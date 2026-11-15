# How Ansible Works

## File Structure
- Inventory file: Contains machine IP addresses and SSH information for remote access
- Playbook (main.yaml): Contains declarative steps for Ansible to execute
- ansible.cfg: Configuration file for Ansible settings (optional)

## The configuration file

- ANSIBLE_CONFIG : environment variable if set
- ansible.cfg: in the current directory
- ~/.ansible.cfg: in the home directory
- /etc/ansible/ansible.cfg

Ansible will process the above list and use the first file found, all others are ignored.

## Roles

- Roles let you automatically load related vars, files, tasks, handlers, and other Ansible artifacts based on a known file structure. After you group your content into roles, you can easily reuse them and share them with other users.

- An Ansible role has a defined directory structure with seven main standard directories. You must include at least one of these directories in each role. You can omit any directories the role does not use. For example:
 
    -  playbooks: 
       - site.yml
       - webservers.yml
       - fooservers.yml

    - Burda site.yml projenin ana playbook'u yani giriş noktası. Hangi makinada hanig rollerin çalışacağını belirliyor.
    - `ansible-playbook site.yml` ile çalıştırılıyor.
    - `role` işin nasıl yapılacağını, playbook (site.yml) neyi nerde çalıştıracağını belirliyor.
    - site.yml yaygın bir isimlendirme. main.yml ya da playbook.yml da yazabilirsin.

- This layout organizes most tasks in roles, with a single inventory file for each environment and a few playbooks in the top-level directory:

```yaml
production                # inventory file for production servers
staging                   # inventory file for staging environment

group_vars/
   group1.yml             # here we assign variables to particular groups
   group2.yml
host_vars/
   hostname1.yml          # here we assign variables to particular systems
   hostname2.yml

library/                  # if any custom modules, put them here (optional)
module_utils/             # if any custom module_utils to support modules, put them here (optional)
filter_plugins/           # if any custom filter plugins, put them here (optional)

site.yml                  # main playbook
webservers.yml            # playbook for webserver tier
dbservers.yml             # playbook for dbserver tier
tasks/                    # task files included from playbooks
    webservers-extra.yml  # <-- avoids confusing playbook with task files
```


```yaml
roles/
    common/               # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case

    webtier/              # same kind of structure as "common" was above, done for the webtier role
    monitoring/           # ""
    fooapp/
```
Kaynak: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_reuse_roles.html

## main.yml

### gather_facts: 

- This module takes care of executing the configured facts modules, the default is to use the ansible.builtin.setup module.
- This module is automatically called by playbooks to gather useful variables about remote hosts that can be used in playbooks.
- Ansible bir playbook'a başlarken makineye bağlanıp onun hakkında bilgi toplar: işletim sistemi, IP adresi, hostname, bellek miktarı gibi. 
- Bunlara facts deniyor ve ansible_facts[...] ile kullanılıyor.
- O yüzden SSH hazır olması için bunu otomatik yapması yerine SSH bağlantısı tamamlandıktan sonraki adıma ekledim.
