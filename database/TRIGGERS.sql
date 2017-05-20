-- TRIGGERS DE VENTAS &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-- &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

drop trigger tri_eliminarItemDespacho;
delimiter &&
	create trigger tri_insetarItemDespacho after insert on ITEM_DESPACHO for each row
	begin
		declare aux_dev int;
        set aux_dev = (select ITE_DEV_cantidad from ITEM_DEVOLUCION where ITE_DEV_ref = new.ITE_DES_ref and ITE_DEV_idPaque = new.ITE_DES_idPaque);
        
        if aux_dev is not null then
			insert into ITEM_VENTA values (new.ITE_DES_ref,new.ITE_DES_idPaque,new.ITE_DES_fecha,new.ITE_DES_idVende,new.ITE_DES_cantidad - aux_dev);
				else
					insert into ITEM_VENTA values (new.ITE_DES_ref,new.ITE_DES_idPaque,new.ITE_DES_fecha,new.ITE_DES_idVende,new.ITE_DES_cantidad);
        end if;
    end &&
delimiter ;


drop trigger tri_actualizarItemDespacho;
delimiter &&
	create trigger tri_actualizarItemDespacho after UPDATE on ITEM_DESPACHO for each row
	begin
		declare aux_dev int;
        set aux_dev = (select ITE_DEV_cantidad from ITEM_DEVOLUCION where ITE_DEV_ref = new.ITE_DES_ref and ITE_DEV_idPaque = new.ITE_DES_idPaque);
        
        if aux_dev is not null then
			 update ITEM_VENTA set ITE_VENT_cantidad = new.ITE_DES_cantidad - aux_dev where ITE_VENT_ref = new.ITE_DES_ref and
				ITE_VENT_idPaque = new.ITE_DES_idPaque;
					else
                    update ITEM_VENTA set ITE_VENT_cantidad = new.ITE_DES_cantidad where ITE_VENT_ref = new.ITE_DES_ref and
				ITE_VENT_idPaque = new.ITE_DES_idPaque;
                
        end if;
    end &&
delimiter ;


/*drop trigger tri_eliminarItemDespacho;
delimiter &&
	create trigger tri_eliminarItemDespacho after delete on ITEM_DESPACHO for each row
	begin
		declare aux_dev int;
			delete from ITEM_VENTA where ITE_VENT_ref = old.ITE_DES_ref and ITE_VENT_idPaque = old.ITE_DES_idPaque;
    end &&
delimiter ;*/

drop trigger tri_insertarItemDevolucion;
delimiter &&
	create trigger tri_insertarItemDevolucion after insert on ITEM_DEVOLUCION for each row
	begin
			update ITEM_VENTA set ITE_VENT_cantidad = ITE_VENT_cantidad - new.ITE_DEV_cantidad where
				ITE_VENT_ref = new.ITE_DEV_ref and ITE_VENT_idPaque = new.ITE_DEV_idPaque; 
    end &&
delimiter ;

drop trigger tri_actualizarItemDevolucion;

delimiter &&
	create trigger tri_actualizarItemDevolucion after update on ITEM_DEVOLUCION for each row
	begin
			declare aux_desp int;
            set aux_desp = (select ITE_DES_cantidad from ITEM_DESPACHO where ITE_DES_ref = new.ITE_DES_ref and 
				ITE_DES_idPaque = new.ITE_DES_idPaque);
                
			update ITEM_VENTA set ITE_VENT_cantidad = aux_desp - new.ITE_DEV_cantidad where
				ITE_VENT_ref = new.ITE_DEV_ref and ITE_VENT_idPaque = new.ITE_DEV_idPaque; 
    end &&
delimiter ;

/*drop trigger tri_eliminarItemDevolucion;
delimiter &&
	create trigger tri_eliminarItemDevolucion after delete on ITEM_DEVOLUCION for each row
	begin
			declare aux_desp int;
            set aux_desp = (select ITE_DES_cantidad from ITEM_DESPACHO where ITE_DES_ref = old.ITE_DES_ref and 
				ITE_DES_idPaque = old.ITE_DES_idPaque);
                
			update ITEM_VENTA set ITE_VENT_cantidad = aux_desp where
				ITE_VENT_ref = new.ITE_DEV_ref and ITE_VENT_idPaque = new.ITE_DEV_idPaque; 
    end &&
delimiter ;*/

drop trigger tri_insertarItemVenta;
delimiter &&
create trigger tri_insertarItemVenta after insert on ITEM_VENTA for each row
	begin
		declare aux_cond boolean;
        declare aux_isEspecial boolean;
        declare aux_cliente int;
        declare aux_precio int;
        declare aux_gananVende float;
        
		-- start transaction;
			set aux_cond = (select VENT_condMin from VENTA where VENT_factura = new.ITE_VENT_ref);
            set aux_cliente = (select VENT_idclienEsp from VENTA where VENT_factura = new.ITE_VENT_ref);
            set aux_isEspecial = isEspecial(aux_cliente);
            
           
            if aux_isEspecial then-- el cliente de la venta es especial
				if aux_cond then-- la condicion minima es tomada en cuenta
					if superaMinimo(new.ITE_VENT_ref,new.ITE_VENT_idPaque,NEW.ite_vent_cantidad) then
						set aux_precio = (select CLI_ESP_precioMin from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
							and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
                        set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
							and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
							else
								set aux_precio = (select CLI_ESP_precioFull from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
									and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
								set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
									and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
                    end if;
                    
						else-- la condicion minima no es tomada en cuenta
							set aux_precio = (select CLI_ESP_precioMin from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
								and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
							set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
								and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
                end if;
                    else-- el cliente no es especial
						set aux_precio = (select PAQ_precioCalle from PAQUETE where PAQ_nombre = new.ITE_VENT_idPaque);
                        set aux_gananVende = ((aux_precio - (precioSobrePaqVend(new.ITE_VENT_idPaque,new.ITE_VENT_idPaque))));
            end if;
			
            set aux_precio = (aux_precio * new.ITE_VENT_cantidad);
            set aux_gananVende = (aux_gananVende * new.ITE_VENT_cantidad);
					
            update ITEM_VENTA set ITE_VENT_gananVende = aux_gananVende where ITE_VENT_ref = new.ITE_VENT_ref and ITE_VENT_idPaque = new.ITE_VENT_idPaque;
			update ITEM_VENTA set ITE_VENT_precio = aux_precio where ITE_VENT_ref = new.ITE_VENT_ref and ITE_VENT_idPaque = new.ITE_VENT_idPaque;	
			call actualizarVenta(new.ITE_VENT_ref);
        -- commit;
    end &&
delimiter ;

drop trigger tri_actualizarItemVenta;
delimiter &&
create trigger tri_actualizarItemVenta after update on ITEM_VENTA for each row
	begin
		declare aux_cond boolean;
        declare aux_isEspecial boolean;
        declare aux_cliente int;
        declare aux_precio int;
        declare aux_gananVende float;
        
		-- start transaction;
			set aux_cond = (select VENT_condMin from VENTA where VENT_factura = new.ITE_VENT_ref);
            set aux_cliente = (select VENT_idclienEsp from VENTA where VENT_factura = new.ITE_VENT_ref);
            set aux_isEspecial = isEspecial(aux_cliente);
            
           
            if aux_isEspecial then-- el cliente de la venta es especial
				if aux_cond then-- la condicion minima es tomada en cuenta
					if superaMinimo(new.ITE_VENT_ref,new.ITE_VENT_idPaque,NEW.ite_vent_cantidad) then
						set aux_precio = (select CLI_ESP_precioMin from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
							and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
                        set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
							and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
							else
								set aux_precio = (select CLI_ESP_precioFull from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
									and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
								set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
									and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
                    end if;
                    
						else-- la condicion minima no es tomada en cuenta
							set aux_precio = (select CLI_ESP_precioMin from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
								and CLI_ESP_idPaque = new.ITE_VENT_idPaque);
							set aux_gananVende = ((select CLI_ESP_porcenVend from CLIENTE_ESPECIAL where CLI_ESP_idClien = aux_cliente 
								and CLI_ESP_idPaque = new.ITE_VENT_idPaque) * aux_precio);    
                end if;
                    else-- el cliente no es especial
						set aux_precio = (select PAQ_precioCalle from PAQUETE where PAQ_nombre = new.ITE_VENT_idPaque);
                        set aux_gananVende = ((aux_precio - (precioSobrePaqVend(new.ITE_VENT_idPaque,new.ITE_VENT_idPaque))));
            end if;
			
            set aux_precio = (aux_precio * new.ITE_VENT_cantidad);
            set aux_gananVende = (aux_gananVende * new.ITE_VENT_cantidad);
					
            update ITEM_VENTA set ITE_VENT_gananVende = aux_gananVende where ITE_VENT_ref = new.ITE_VENT_ref and ITE_VENT_idPaque = new.ITE_VENT_idPaque;
			update ITEM_VENTA set ITE_VENT_precio = aux_precio where ITE_VENT_ref = new.ITE_VENT_ref and ITE_VENT_idPaque = new.ITE_VENT_idPaque;	
			call actualizarVenta(new.ITE_VENT_ref);
        -- commit;
    end &&
delimiter ;






