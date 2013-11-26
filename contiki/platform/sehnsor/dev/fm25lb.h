#ifndef FM25LB_H_
#define FM25LB_H_

#define FM25LB_WRITE_ENABLE_COMMAND  0x06
#define FM25LB_WRITE_DISABLE_COMMAND 0x04
#define FM25LB_READ_STATUS_COMMAND   0x05
#define FM25LB_WRITE_STATUS_COMMAND  0x01
#define FM25LB_READ_COMMAND          0x03
#define FM25LB_WRITE_COMMAND         0x02

/* /brief adds the 9th bit of the address to a command */
#define FM25LB_ADD_ADDRESS_BIT(address, command) \
  (((address & 0x100) >> 5) | command)

void fm25lb_init();
int fm25lb_read(uint16_t address, uint16_t len, uint8_t *buf);
int fm25lb_write(uint16_t address, uint16_t len, uint8_t *buf);

#endif
