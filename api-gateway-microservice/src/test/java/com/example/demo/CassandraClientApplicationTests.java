package com.example.demo;

import com.yugabyte.app.yugastore.YugastoreApiGateway;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(
    classes = YugastoreApiGateway.class,
    properties = {
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
    })
public class CassandraClientApplicationTests {

	@Test
	public void contextLoads() {
	}

}
