package com.yugabyte.app.yugastore;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.cassandra.core.CassandraTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.yugabyte.app.yugastore.repo.ProductInventoryRepository;
import com.yugabyte.app.yugastore.repo.ProductMetadataRepo;
import com.yugabyte.app.yugastore.repo.ProductRankingRepository;

// "test" profile keeps YugabyteYCQLConfig's @Profile("local") beans out of the context;
// CassandraTemplate and the Cassandra repositories are mocked because Spring Boot
// auto-configures them regardless of that profile, which would otherwise try to reach
// 127.0.0.1:9042.
@SpringBootTest
@ActiveProfiles("test")
public class YugastoreProductsTests {

	@MockBean
	private CassandraTemplate cassandraTemplate;

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
