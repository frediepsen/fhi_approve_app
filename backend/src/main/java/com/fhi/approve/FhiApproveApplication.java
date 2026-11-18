package com.fhi.approve;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class FhiApproveApplication {
    public static void main(String[] args) {
        SpringApplication.run(FhiApproveApplication.class, args);
    }
}
