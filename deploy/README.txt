部署文件说明
============

文件列表:
---------
1. nginx.conf          - Nginx配置文件
2. h5project.service   - systemd服务文件
3. deploy.sh           - 自动部署脚本（服务器上运行）
4. docker-compose.prod.yml - 生产环境Docker配置
5. test_local.sh       - 本地测试脚本

本地测试:
---------
./deploy/test_local.sh

服务器部署:
-----------
1. 上传整个项目到服务器
2. 运行: ./deploy/deploy.sh

注意事项:
---------
- 部署前修改 h5project.service 中的 JWT_SECRET
- 修改 nginx.conf 中的 server_name
- 确保服务器已安装: Go, Docker, Nginx

