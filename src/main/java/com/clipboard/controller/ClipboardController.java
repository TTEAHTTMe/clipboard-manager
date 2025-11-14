package com.clipboard.controller;

import com.clipboard.entity.ClipboardItem;
import com.clipboard.service.ClipboardItemService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
public class ClipboardController {
    
    @Autowired
    private ClipboardItemService clipboardItemService;
    
    @GetMapping("/")
    public String index(Model model) {
        List<ClipboardItem> items = clipboardItemService.getAllItems();
        model.addAttribute("items", items);
        model.addAttribute("itemCount", items.size());
        return "index";
    }
    
    @PostMapping("/add")
    public String addItem(@RequestParam("content") String content, Model model) {
        try {
            if (content != null && !content.trim().isEmpty()) {
                clipboardItemService.addItem(content.trim());
            }
            return "redirect:/";
        } catch (Exception e) {
            // 如果添加失败，返回错误信息到页面
            model.addAttribute("error", "添加失败: " + e.getMessage());
            List<ClipboardItem> items = clipboardItemService.getAllItems();
            model.addAttribute("items", items);
            model.addAttribute("itemCount", items.size());
            return "index";
        }
    }
    
    @PostMapping("/delete/{id}")
    public String deleteItem(@PathVariable("id") Long id) {
        clipboardItemService.deleteItem(id);
        return "redirect:/";
    }
    
    @PostMapping("/delete/bulk")
    public String deleteBulkItems(@RequestParam("ids") String ids) {
        try {
            String[] idArray = ids.split(",");
            for (String idStr : idArray) {
                try {
                    Long id = Long.parseLong(idStr.trim());
                    clipboardItemService.deleteItem(id);
                } catch (NumberFormatException e) {
                    // 忽略格式错误的ID
                    continue;
                }
            }
        } catch (Exception e) {
            // 记录错误日志，但仍然重定向到主页
            e.printStackTrace();
        }
        return "redirect:/";
    }
    
    @PostMapping("/clear")
    public String clearAllItems() {
        clipboardItemService.clearAllItems();
        return "redirect:/";
    }
    
    @PostMapping("/update/{id}")
    @ResponseBody
    public ClipboardItem updateItem(@PathVariable("id") Long id, @RequestParam("content") String content) {
        if (content != null && !content.trim().isEmpty()) {
            return clipboardItemService.updateItem(id, content.trim());
        }
        return null;
    }
    
    @PostMapping("/update/annotation/{id}")
    @ResponseBody
    public ClipboardItem updateAnnotation(@PathVariable("id") Long id, @RequestParam("annotation") String annotation) {
        return clipboardItemService.updateAnnotation(id, annotation);
    }
    
    @GetMapping("/api/items")
    @ResponseBody
    public List<ClipboardItem> getAllItemsApi() {
        return clipboardItemService.getAllItems();
    }
    
    @PostMapping("/api/items")
    @ResponseBody
    public ClipboardItem addItemApi(@RequestBody String content) {
        if (content != null && !content.trim().isEmpty()) {
            return clipboardItemService.addItem(content.trim());
        }
        return null;
    }
    
    @DeleteMapping("/api/items/{id}")
    @ResponseBody
    public void deleteItemApi(@PathVariable("id") Long id) {
        clipboardItemService.deleteItem(id);
    }
}