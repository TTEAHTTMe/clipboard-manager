package com.clipboard;

import com.clipboard.service.ClipboardItemService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class ClipboardManagerApplication {

    @Autowired
    private ClipboardItemService clipboardItemService;

    public static void main(String[] args) {
        SpringApplication.run(ClipboardManagerApplication.class, args);
    }

    @Bean
    public CommandLineRunner initializeDatabase() {
        return args -> {
            clipboardItemService.initializeDatabase();
        };
    }

}