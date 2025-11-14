# 剪贴板管理器

一个基于Spring Boot的剪贴板管理应用，使用SQLite数据库和Thymeleaf模板引擎。

## 功能特性

- ✅ 添加剪贴板内容
- ✅ 复制内容到系统剪贴板
- ✅ 删除剪贴板内容
- ✅ 自动编号和重新排序
- ✅ 内容展开/折叠功能
- ✅ 现代化UI设计
- ✅ 响应式布局
- ✅ 本地SQLite数据存储

## 技术栈

- **后端**: Spring Boot 2.7.18, JDK 1.8
- **数据库**: SQLite
- **前端**: Thymeleaf, HTML5, CSS3, JavaScript
- **构建工具**: Maven

## 快速开始

### 1. 克隆项目
```bash
git clone <项目地址>
cd clipboard-manager
```

### 2. 构建项目
```bash
mvn clean install
```

### 3. 运行应用
```bash
mvn spring-boot:run
```

或者运行打包后的jar文件：
```bash
java -jar target/clipboard-manager-0.0.1-SNAPSHOT.jar
```

### 4. 访问应用
打开浏览器访问: http://localhost:2345

## 使用说明

### 添加内容
1. 在顶部文本框中输入内容
2. 点击"添加内容"按钮
3. 内容会自动保存并显示在列表中

### 复制内容
1. 找到要复制的内容
2. 点击对应的"复制"按钮
3. 内容会复制到系统剪贴板
4. 按钮会短暂显示"已复制!"

### 删除内容
1. 找到要删除的内容
2. 点击对应的"删除"按钮
3. 在确认对话框中点击"删除"
4. 内容会被删除，后续编号会自动重新排序

### 展开/折叠内容
- 对于长内容，默认只显示前100个字符
- 点击"展开"按钮查看完整内容
- 点击"收起"按钮返回预览模式

## 项目结构

```
src/
├── main/
│   ├── java/com/clipboard/
│   │   ├── ClipboardManagerApplication.java  # 主启动类
│   │   ├── config/
│   │   │   └── SQLiteDialect.java            # SQLite方言配置
│   │   ├── controller/
│   │   │   └── ClipboardController.java      # Web控制器
│   │   ├── entity/
│   │   │   └── ClipboardItem.java          # 实体类
│   │   ├── repository/
│   │   │   └── ClipboardItemRepository.java # 数据访问层
│   │   └── service/
│   │       └── ClipboardItemService.java   # 业务逻辑层
│   └── resources/
│       ├── static/
│       │   ├── css/
│       │   │   └── style.css               # 样式文件
│       │   └── js/
│       │       └── clipboard.js              # JavaScript交互
│       ├── templates/
│       │   └── index.html                    # Thymeleaf模板
│       └── application.properties            # 应用配置
```

## 配置说明

### 应用端口
默认端口为2345，可在`application.properties`中修改：
```properties
server.port=2345
```

### 数据库
使用SQLite数据库，数据文件为`clipboard.db`，会自动创建在项目根目录。

## API接口

除了Web界面，应用还提供了REST API：

- `GET /api/items` - 获取所有剪贴板内容
- `POST /api/items` - 添加新的剪贴板内容
- `DELETE /api/items/{id}` - 删除指定内容

## 开发说明

### 添加新功能
1. 在`entity`包中添加新的实体类（如果需要）
2. 在`repository`包中添加对应的Repository接口
3. 在`service`包中添加业务逻辑
4. 在`controller`包中添加控制器方法
5. 更新前端模板和JavaScript

### 数据库操作
使用Spring Data JPA进行数据库操作，支持方法名解析查询和自定义查询。

## 注意事项

- 确保JDK版本为1.8
- SQLite数据库文件会在首次运行时自动创建
- 前端使用Thymeleaf模板引擎，支持服务端渲染
- 所有删除操作都有确认对话框防止误操作

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交Issue或Pull Request。