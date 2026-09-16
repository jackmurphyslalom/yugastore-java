package com.yugabyte.app.yugastore;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;

import com.yugabyte.app.yugastore.repo.ProductInventoryRepository;
import com.yugabyte.app.yugastore.repo.ProductMetadataRepo;
import com.yugabyte.app.yugastore.repo.ProductRankingRepository;

// Cassandra repositories are auto-configuration excluded in the "test" profile
// (see src/test/resources/application-test.yml). @MockBean supplies stand-ins
// so downstream services can be autowired during Spring context startup.
@SpringBootTest
@ActiveProfiles("test")
public class CassandraClientApplicationTests {

	@MockBean
	private ProductInventoryRepository productInventoryRepository;

	@MockBean
	private ProductMetadataRepo productMetadataRepo;

	@MockBean
	private ProductRankingRepository productRankingRepository;

	@Test
	public void contextLoads() {
	}

}
