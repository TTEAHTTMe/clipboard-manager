package com.clipboard.service;

import com.clipboard.entity.ClipboardItem;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class ClipboardItemService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    private final RowMapper<ClipboardItem> rowMapper = new RowMapper<ClipboardItem>() {
        @Override
        public ClipboardItem mapRow(ResultSet rs, int rowNum) throws SQLException {
            ClipboardItem item = new ClipboardItem();
            item.setId(rs.getLong("id"));
            item.setItemNumber(rs.getInt("item_number"));
            item.setContent(rs.getString("content"));
            item.setAnnotation(rs.getString("annotation"));
            // 正确读取数据库中的创建时间
            try {
                String timeStr = rs.getString("created_at");
                if (timeStr != null && !timeStr.trim().isEmpty()) {
                    try {
                        java.sql.Timestamp timestamp = rs.getTimestamp("created_at");
                        if (timestamp != null) {
                            item.setCreatedAt(timestamp.toLocalDateTime());
                        } else {
                            item.setCreatedAt(LocalDateTime.of(2024, 1, 1, 0, 0));
                        }
                    } catch (Exception parseEx) {
                        // 如果解析失败，尝试手动解析字符串
                        try {
                            item.setCreatedAt(LocalDateTime.parse(timeStr.replace(" ", "T")));
                        } catch (Exception manualEx) {
                            item.setCreatedAt(LocalDateTime.of(2024, 1, 1, 0, 0));
                        }
                    }
                } else {
                    item.setCreatedAt(LocalDateTime.of(2024, 1, 1, 0, 0));
                }
            } catch (Exception e) {
                item.setCreatedAt(LocalDateTime.of(2024, 1, 1, 0, 0));
            }
            return item;
        }
    };
    
    public List<ClipboardItem> getAllItems() {
        String sql = "SELECT * FROM clipboard_items ORDER BY id DESC";
        return jdbcTemplate.query(sql, rowMapper);
    }
    
    public ClipboardItem addItem(String content) {
        try {
            // 获取最大编号
            String maxSql = "SELECT MAX(item_number) FROM clipboard_items";
            Integer maxNumber = null;
            try {
                maxNumber = jdbcTemplate.queryForObject(maxSql, Integer.class);
            } catch (Exception e) {
                // 表可能不存在或没有数据，从1开始
                maxNumber = null;
            }
            Integer nextNumber = (maxNumber != null) ? maxNumber + 1 : 1;
            
            // 插入新记录
            String insertSql = "INSERT INTO clipboard_items (item_number, content, created_at) VALUES (?, ?, ?)";
            LocalDateTime now = LocalDateTime.now();
            jdbcTemplate.update(insertSql, nextNumber, content, now);
            
            // 返回新创建的对象 - 使用更安全的查询方式
            String selectSql = "SELECT * FROM clipboard_items WHERE item_number = ? ORDER BY id DESC LIMIT 1";
            List<ClipboardItem> items = jdbcTemplate.query(selectSql, rowMapper, nextNumber);
            return items.isEmpty() ? null : items.get(0);
        } catch (Exception e) {
            throw new RuntimeException("添加剪贴板项目失败: " + e.getMessage(), e);
        }
    }
    
    public void deleteItem(Long id) {
        // 先获取被删除项目的编号
        String selectSql = "SELECT item_number FROM clipboard_items WHERE id = ?";
        Integer deletedNumber = jdbcTemplate.queryForObject(selectSql, Integer.class, id);
        
        if (deletedNumber != null) {
            // 删除记录
            String deleteSql = "DELETE FROM clipboard_items WHERE id = ?";
            jdbcTemplate.update(deleteSql, id);
            
            // 重新排序后续编号
            String updateSql = "UPDATE clipboard_items SET item_number = item_number - 1 WHERE item_number > ?";
            jdbcTemplate.update(updateSql, deletedNumber);
        }
    }
    
    public ClipboardItem updateItem(Long id, String newContent) {
        String updateSql = "UPDATE clipboard_items SET content = ? WHERE id = ?";
        jdbcTemplate.update(updateSql, newContent, id);
        
        String selectSql = "SELECT * FROM clipboard_items WHERE id = ?";
        return jdbcTemplate.queryForObject(selectSql, rowMapper, id);
    }
    
    public ClipboardItem updateAnnotation(Long id, String annotation) {
        String updateSql = "UPDATE clipboard_items SET annotation = ? WHERE id = ?";
        jdbcTemplate.update(updateSql, annotation, id);
        
        String selectSql = "SELECT * FROM clipboard_items WHERE id = ?";
        return jdbcTemplate.queryForObject(selectSql, rowMapper, id);
    }
    
    public long getItemCount() {
        String sql = "SELECT COUNT(*) FROM clipboard_items";
        return jdbcTemplate.queryForObject(sql, Long.class);
    }
    
    public void clearAllItems() {
        String sql = "DELETE FROM clipboard_items";
        jdbcTemplate.update(sql);
    }
    
    // 初始化数据库表
    public void initializeDatabase() {
        String createTableSql = "CREATE TABLE IF NOT EXISTS clipboard_items (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "item_number INTEGER NOT NULL," +
                "content TEXT NOT NULL," +
                "annotation TEXT," +
                "created_at TIMESTAMP NOT NULL" +
                ")";
        jdbcTemplate.execute(createTableSql);
        
        // 添加标注字段（如果表已存在但缺少该字段）
        String addAnnotationColumnSql = "ALTER TABLE clipboard_items ADD COLUMN annotation TEXT";
        try {
            jdbcTemplate.execute(addAnnotationColumnSql);
        } catch (Exception e) {
            // 字段可能已存在，忽略错误
        }
    }
}