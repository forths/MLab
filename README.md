# MLab
“云上炼丹师”中的云。

# MLab构成
MLab是为云上炼丹师服务的云基础设施。由以下部分组成：
- 最小CPU硬件：x86-64 CPU / 128G RAM / 512G SSD * 2 / 10GbE NIC / 8T HDD * 8
- 最小CUDA硬件：x86-64 CPU / 128G RAM / 512G SSD / 10GbE NIC /CUDA * 1
- 操作系统：Ubuntu 20.04 Server发行版（安装Nvidia最新驱动）
- K8s集群
- Ceph存储
- MLab HomePod

# MLab HomePod
迄今为止最先进的容器化PyTorch训练环境。  
MLab HomePod以Docker image形式封装，也是我们的深度学习训练环境。HomePod有着鲜明的特点：
- 基于最新的Ubuntu LTS；
- 基于LTS仓库中最新的KDE；
- 使用中国时区；
- 使用最新版本的PyTorch；
- 使用最新版本的Conda；
- 使用比较新版本的CUDA；
- 使用比较新版本的MKL；
- 使用最新版本的VS Code IDE；
- 使用最新版本的Chrome浏览器；
- 无缝使用Deepvac规范；
- 无缝构建和测试libdeepvac；
- 包含有kdiff3、kompare等诸多开发工具。

## 1. 部署
MLab HomePod有三种部署方式：
- 纯粹的Docker命令行方式：
```bash
docker run --gpus all -it --entrypoint=/bin/bash gemfield/deepvac:11.0.3-cudnn8-devel-ubuntu20.04
```
部署且运行后只能在命令行里工作。
- 图形化的Docker部署方式：
```bash
docker run --gpus all -it -p 7030:7030 -p 5900:5900 gemfield/deepvac:11.0.3-cudnn8-devel-ubuntu20.04
```
部署后可以在vnc客户端和浏览器中访问图形界面。
- k8s集群部署方式（需要k8s集群运维经验，适合小团队的协作管理）：
```bash
#针对自身的集群环境修改yaml后
kubectl apply -f HomePod/homepod.yaml
kubectl apply -f HomePod/airlock.yaml
kubectl apply -f HomePod/uploadmlab.yaml
kubectl apply -f HomePod/network.yaml
```
部署后可以在vnc客户端和浏览器中访问图形界面，这种方式适合小团队的协作和管理。

## 2. 登录
三种方式中的第一种无需赘述，后两种部署方式都使用的是图形界面，支持两种方式访问：
- 1，浏览器(http://your_host:7030);
- 2，realvnc客户端：https://www.realvnc.com/en/connect/download/viewer/ 。

其中，浏览器方式的优点是方便；VNC客户端方式的优点是流畅，且功能更多。

## 3. 密码与登出
HomePod默认提供了一个普通用户和root用户：
- 普通用户初始密码为：gemfield
- root用户初始密码为：<请咨询maintainer>

为了安全，用户在初始登录HomePod后，需要：
- 修改自己的用户密码；
- 修改root用户的密码；
- 公司和家庭以外环境使用HomePod需要提前报备；
- 离开电脑5分钟以上，需要手工锁定屏幕（KDE -> Leave -> Lock(Lock screen)）。

## 4. 文件权限问题解决
在HomePod中工作的时候，默认都在自己的用户下工作。如果遇到历史遗留文件的权限问题，那么切换为root用户：
- 如果该文件是自己所有，则使用chown命令将文件的owner更改为自己；
- 如果该文件是公共所有，则使用chmod命令将文件的read权限为所有人打开。

完成权限的更改后，再通过exit命令从root用户退回到自己的用户。注意：**不能在root会话中新建会话！！！**。

## 5. 网络策略（仅限k8s集群部署方式）
HomePod为组织内部使用的开发环境，因此默认配有较为严格的防火墙策略。在HomePod上，用户**只能连接MLab代码服务**。除此之外，用户无法访问（也不应该访问）**其它任何服务器**（首次发现某个漏洞的人，发30元红包）。

然而，用户在HomePod上仍然会有一些合理的（或者半合理的）联网需求，我们总结如下：
- 上传或者下载一些数据集到HomePod上（合理需求）；
- HomePod上使用包管理工具（pip、apt等）安装软件包（半合理需求）；
- 下载HomePod上训练结果的输出，分发给客户或其它测试人员（半合理需求）。

为了实现这些合理或者半合理需求，我们提供了**Airlock Pod**（ai5.gemfield.org:27031）。Airlock Pod和HomePod共享一个docker镜像，且共享/opt/public/airlock目录。区别在于3点：
- Airlock Pod可以访问外部网络；
- Airlock Pod对/opt/public/airlock 目录有写权限；
- Airlock Pod没有隐私可言。

#### 5.1 上传或者下载一些数据集到HomePod上
使用Airlock Pod。一旦数据来到Airlock Pod的/opt/public/airlock目录下，用户可以从自己的HomePod中拷贝到自己的HomePod本地。
那么数据如何来到Airlock Pod的/opt/public/airlock目录下呢？有多种方法：
- 在Airlock Pod上使用ftp、wget、scp、git等工具，从外部环境下载到此目录；
- 使用http://ai5.gemfield.org:5212 上传服务上传（该服务支持webdav挂载到本地，详情请咨询管理员）。

#### 5.2 HomePod上使用包管理工具（pip、apt等）安装软件包
软件包按照被使用的普及程度分为两类：基础型软件包、特定软件包。  
基础性软件包就是几乎人人都会用到的，比如numpy、cmake、cv2等；
特定软件包就是几乎只有自己的特定项目会使用到，比如fonttools。

基础软件包和特定软件包都提供了临时安装方法（所谓临时安装，就是在HomePod重启后会丢失）：
- pip包临时安装：
```bash
# 在airlock上
gemfield@airlock:/opt/public/airlock/pip$ pip download <pip-package>

# 切换到homepod上
username@homepod:/opt/public/airlock/pip$ pip install *
```
- apt包临时安装：
```
# 在airlock上（这种方式下载deb包到当前目录）
gemfield@airlock:/opt/public/airlock/apt$ apt-get download <apt-package>
# 或者（这种方式下载该包及所有的依赖包到/var/cache/apt/archives）
gemfield@airlock:/opt/public/airlock/apt$ apt-get install --download-only <apt-package>


# 切换到homepod上
root@homepod:/opt/public/airlock/apt$ dpkg -i <apt-package>
```

此外，基础软件包应该固化到HomePod的image中。用户按照如下的方法提交固化申请：
- 将安装步骤封装为bash脚本，在Airlock Pod上测试成功（一定要测试成功！！！）；
- 然后该脚本连同安装需求描述提交到https://github.com/DeepVAC/MLab 的issues里，通知管理员。

#### 5.3 下载HomePod上训练结果的输出，分发给客户或其它测试人员
这个是罕见需求，目前只能：
- 联系管理员。

## 6. 在HomePod上维护github项目（仅限k8s集群部署方式）
通常情况下，如果想要参与github项目的开发维护，则直接在自己的私人电脑或者办公电脑上完成即可。但有时候，这些项目的开发维护需要借助MLab HomePod上的资源（比如CUDA设备、数据集、已训练模型等），但由于HomePod的网络策略，我们并没有办法直接在HomePod上访问github这样的外网。那则么办呢？借助MLab代码服务。
#### 6.1 申请在HomePod上维护某github项目
只有符合产品研发需要的github项目才会被批准。批准的标志就是该github项目会出现在MLab代码服务上。下文我们就以DeepVAC项目为例(https://github.com/DeepVAC/deepvac)。  
HomePod用户向管理员发出在HomePod上维护DeepVAC的申请，管理员批准，DeepVAC项目出现在MLab代码服务上：http://ai1.gemfield.org/deepvac/deepvac

#### 6.2 在办公电脑上配置git
- 在github上fork DeepVAC仓库；
- 克隆你的fork：git clone https://github.com/<your_name>/deepvac
- 在仓库中添加remote（注意，由于前述的clone仓库，git已经默认帮你配好了origin这个默认的remote）：
```bash
#添加mlab remote
git remote add mlab http://ai1.gemfield.org/deepvac/deepvac

#添加upstream
git remote add upstream https://github.com/DeepVAC/deepvac
```
- 验证remote添加成功
```bash
gemfield@ThinkPad-X1C:/github/deepvac$ git remote -v
mlab    http://ai1.gemfield.org/deepvac/deepvac (fetch)
mlab    http://ai1.gemfield.org/deepvac/deepvac (push) 
origin  https://github.com/<your_name>/deepvac (fetch)
origin  https://github.com/<your_name>/deepvac (push)
upstream https://github.com/DeepVAC/deepvac (fetch)
upstream https://github.com/DeepVAC/deepvac (push)
```
#### 6.3 在办公电脑上新建轻量级工作分支
假设你现在需要往deepvac提交feature1。则需要在办公电脑上（想想为什么？）按照如下的步骤：
```bash
#同步上游
git fetch upstream
git rebase upstream/master
#新建工作分支
git checkout -b feature_1
#同步到MLab
git push mlab feature_1
```
注意：完成上述步骤后，办公电脑上该仓库就停留在feature_1分支上。

#### 6.4 在HomePod上开发、测试、提交
以下步骤在HomePod上：
```bash
#克隆代码
git clone http://ai1.gemfield.org/deepvac/deepvac

#切换（注意不是新建）
git checkout feature_1

#开发、测试
......
git add
git commit -m "xxx"

#将feature_1同步到mlab上
git push feature_1
```

#### 6.5 在办公电脑上同步feature_1分支
以下步骤在办公电脑上，且在之前停留的feature_1分支上：
```bash
#同步feature_1分支
git fetch mlab
git rebase mlab/feature_1

#同步到自己fork的deepvac上
git push feature_1
```

#### 6.6 在github上创建PR
在github网页上，切换到自己fork的deepvac项目上，创建PR。

**注意：自始至终，办公电脑上没有发生任何的开发。这不是必须的，但不这么做会增加git流程的复杂度。**
