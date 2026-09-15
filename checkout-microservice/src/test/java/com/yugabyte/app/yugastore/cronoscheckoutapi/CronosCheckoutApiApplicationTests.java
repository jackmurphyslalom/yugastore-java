package com.yugabyte.app.yugastore.cronoscheckoutapi;


import com.yugabyte.app.yugastore.cronoscheckoutapi.repositories.ProductInventoryRepository;
import com.yugabyte.app.yugastore.cronoscheckoutapi.rest.clients.ProductCatalogRestClient;
import com.yugabyte.app.yugastore.cronoscheckoutapi.rest.clients.ShoppingCartRestClient;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.cassandra.core.CassandraOperations;

@SpringBootTest(
    classes = YugastoreCheckout.class,
    properties = {
        "spring.profiles.active=test",
        "eureka.client.enabled=false",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.cassandra.CassandraAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.cassandra.CassandraDataAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.cassandra.CassandraRepositoriesAutoConfiguration"
    })
public class CronosCheckoutApiApplicationTests {

	@MockBean
	private CassandraOperations cassandraOperations;

	@MockBean
	private ProductInventoryRepository productInventoryRepository;

	@MockBean
	private ProductCatalogRestClient productCatalogRestClient;

	@MockBean
	private ShoppingCartRestClient shoppingCartRestClient;

	@Test
	public void contextLoads() {
	}

}
