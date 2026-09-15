package com.yugabyte.app.yugastore;

import com.yugabyte.app.yugastore.cart.YugastoreCart;
import com.yugabyte.app.yugastore.cart.repositories.ShoppingCartRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;

@SpringBootTest(
    classes = YugastoreCart.class,
    properties = {
        "eureka.client.enabled=false",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
            + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration"
    })
public class YugastoreCartTests {

	@MockBean
	private ShoppingCartRepository shoppingCartRepository;

	@Test
	public void contextLoads() {
	}

}
