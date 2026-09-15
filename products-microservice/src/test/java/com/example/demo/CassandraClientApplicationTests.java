package com.example.demo;

import com.datastax.oss.driver.api.core.CqlSession;
import com.yugabyte.app.yugastore.YugastoreProducts;
import com.yugabyte.app.yugastore.repo.ProductInventoryRepository;
import com.yugabyte.app.yugastore.repo.ProductMetadataRepo;
import com.yugabyte.app.yugastore.repo.ProductRankingRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;

@SpringBootTest(
    classes = YugastoreProducts.class,
    properties = {
        "spring.profiles.active=test",
        "eureka.client.enabled=false",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.cassandra.CassandraAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.cassandra.CassandraDataAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.cassandra.CassandraRepositoriesAutoConfiguration"
    })
public class CassandraClientApplicationTests {

	@MockBean
	private CqlSession cqlSession;

	@MockBean
	private ProductMetadataRepo productMetadataRepo;

	@MockBean
	private ProductInventoryRepository productInventoryRepository;

	@MockBean
	private ProductRankingRepository productRankingRepository;

	@Test
	public void contextLoads() {
	}

}
