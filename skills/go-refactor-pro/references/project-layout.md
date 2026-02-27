# Go 标准项目布局 (Standard Layout)

当 Agent 发现项目目录结构混乱时，应引导用户进行归位重构：

- **/cmd**: 存放各应用程序的可执行文件入口（main.go）。
- **/internal**: 存放私有代码，禁止被其他项目导入，重构的核心逻辑应收敛于此。
- **/pkg**: 存放可供外部导入的库代码。
- **/api**: API 协议定义（Swagger, Proto）。
- **/scripts**: 存放构建、分析、CI 自动化脚本。