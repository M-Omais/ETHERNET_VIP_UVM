#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _DEBUG
#undef _DEBUG
#include <Python.h>
#define _DEBUG
#else
#include <Python.h>
#endif
#include < stdint.h>
#include <svdpi.h>
#include "vpi_user.h"

using namespace std;
static PyObject *xgmii_frame = NULL;
static PyObject *create_xgmii_eth_frame_func = NULL;
static PyObject *decode_xgmii_frame_func = NULL;

typedef struct
{
    // Ethernet fields
    unsigned long long dst_mac;
    unsigned long long src_mac;
    unsigned short eth_type;
    // ARP fields
    unsigned short hwtype;
    unsigned short ptype;
    unsigned char hwlen;
    unsigned char plen;
    unsigned short op;

    // IP fields
    unsigned char version;
    unsigned char ihl;
    unsigned char tos_dscp;
    unsigned char tos_ecn;
    unsigned short length;
    unsigned short identification;
    unsigned char flags;
    unsigned short fragment_offset;
    unsigned char ttl;
    unsigned char protocol;
    unsigned short header_checksum;
    unsigned int source_ip;
    unsigned int dest_ip;

    // UDP fields
    unsigned short source_port;
    unsigned short dest_port;
    unsigned short udp_length;
    unsigned short udp_checksum;

    // Payload
    unsigned char payload[1500]; // Max Ethernet payload
    int payload_size;

    // Status
    int valid; // 0 = invalid, 1 = valid
} decoded_packet_t;
static unsigned long long get_dict_ull(PyObject *dict, const char *key, unsigned long long default_val)
{
    PyObject *item = PyDict_GetItemString(dict, key);
    if (!item)
        return default_val;

    if (PyLong_Check(item))
    {
        return PyLong_AsUnsignedLongLong(item);
    }
    return default_val;
}

// Helper function to safely get integer from dictionary
static long get_dict_long(PyObject *dict, const char *key, long default_val)
{
    PyObject *item = PyDict_GetItemString(dict, key);
    if (!item)
        return default_val;

    if (PyLong_Check(item))
    {
        return PyLong_AsLong(item);
    }
    return default_val;
}

// Helper function to safely get bytes from dictionary
static int get_dict_bytes(PyObject *dict, const char *key, unsigned char *buffer, int max_size)
{
    PyObject *item = PyDict_GetItemString(dict, key);
    if (!item)
        return 0;

    if (PyBytes_Check(item))
    {
        Py_ssize_t size;
        char *data;
        if (PyBytes_AsStringAndSize(item, &data, &size) == 0)
        {
            int copy_size = (size < max_size) ? size : max_size;
            memcpy(buffer, data, copy_size);
            return copy_size;
        }
    }
    return 0;
}

int init_python_wrapper()
{
    Py_Initialize();
    // Add current directory to sys.path
    PyRun_SimpleString("import sys\n"
                       "sys.path.insert(0, '')\n");
    PyObject *sys_path = PySys_GetObject("path");
    if (!sys_path)
    {
        printf("Error: Could not get sys.path\n");
        PyErr_Print();
        return -1;
    }

    // Debug: Print current Python paths
    printf("Current Python sys.path:\n");
    for (int i = 0; i < PyList_Size(sys_path); i++)
    {
        PyObject *item = PyList_GetItem(sys_path, i);
        const char *path = PyUnicode_AsUTF8(item);
        if (path)
        {
            printf("  [%d] %s\n", i, path);
        }
    }

    // Add custom script directory
    const char *paths[] = {
        "src/python",
        "venv\\Lib\\site-packages"};

    for (int i = 0; i < sizeof(paths) / sizeof(paths[0]); i++)
    {
        PyObject *path = PyUnicode_FromString(paths[i]);
        if (!path)
        {
            printf("Error creating path object for %s\n", paths[i]);
            continue;
        }

        if (PyList_Append(sys_path, path) == -1)
        {
            printf("Error adding path: %s\n", paths[i]);
            PyErr_Print();
        }
        // else {
        //     printf("Added to sys.path: %s\n", paths[i]);
        // }
        Py_DECREF(path);
    }

    // Import our Python module
    printf("Importing xgmii_frame module...\n");
    xgmii_frame = PyImport_ImportModule("xgmii_frame");
    if (!xgmii_frame)
    {
        printf("Error importing module:\n");
        PyErr_Print();

        // Check if module exists
        PyObject *module_name = PyUnicode_FromString("xgmii_frame");
        if (PyImport_Import(module_name) == NULL)
        {
            printf("Module xgmii_frame cannot be imported. Check these locations:\n");
            for (int i = 0; i < PyList_Size(sys_path); i++)
            {
                PyObject *item = PyList_GetItem(sys_path, i);
                const char *path = PyUnicode_AsUTF8(item);
                if (path)
                {
                    printf("  - %s/xgmii_frame.py\n", path);
                }
            }
        }
        Py_XDECREF(module_name);
        return -1;
    }

    // Get function references
    create_xgmii_eth_frame_func = PyObject_GetAttrString(xgmii_frame, "xgmii_eth_frame");
    decode_xgmii_frame_func = PyObject_GetAttrString(xgmii_frame, "decode_xgmii_frame");
    if (!create_xgmii_eth_frame_func || !decode_xgmii_frame_func)
    {
        PyErr_Print();
        fprintf(stderr, "Failed to retrieve one or more Python functions\n");
        return 1;
    }

    printf("Python wrapper initialized successfully\n");
    return 0;
}
// Clean up Python resources before exiting
void cleanup_python_wrapper()
{
    if (create_xgmii_eth_frame_func)
        Py_DECREF(create_xgmii_eth_frame_func);
    Py_Finalize(); // Shut down the Python interpreter
}
int convert_python_list_to_c_array(PyObject *py_list, unsigned long long *data_val, unsigned long long *ctrl_val, int max_size)
{
    if (!PyList_Check(py_list))
    {
        printf("Error: Python object is not a list\n");
        return -1;
    }

    Py_ssize_t list_size = PyList_Size(py_list);
    if (list_size > max_size)
    {
        printf("Error: List too large for output arrays (max_size=%d)\n", max_size);
        return -1;
    }

    for (Py_ssize_t i = 0; i < list_size; i++)
    {
        PyObject *item = PyList_GetItem(py_list, i);

        if (PyTuple_Check(item))
        {
            // Expect (data, ctrl) tuple
            if (PyTuple_Size(item) != 2)
            {
                printf("Error: Tuple at index %zd does not have 2 elements\n", i);
                return -1;
            }

            PyObject *data_obj = PyTuple_GetItem(item, 0);
            PyObject *ctrl_obj = PyTuple_GetItem(item, 1);

            if (!PyLong_Check(data_obj) || !PyLong_Check(ctrl_obj))
            {
                printf("Error: Tuple elements at index %zd are not integers\n", i);
                return -1;
            }

            data_val[i] = PyLong_AsUnsignedLongLong(data_obj);
            ctrl_val[i] = PyLong_AsUnsignedLongLong(ctrl_obj);
        }
        else if (PyLong_Check(item))
        {
            // Handle flat list of integers (ctrl=0 by default)
            unsigned long long val = PyLong_AsUnsignedLongLong(item);
            data_val[i] = val;
            ctrl_val[i] = 0;
        }
        else
        {
            printf("Error: List item %zd is neither tuple nor integer\n", i);
            return -1;
        }
    }

    return (int)list_size; // number of entries filled
}
int xgmii_eth_frame(char *src_mac = NULL, char *dst_mac = NULL, char *src_ip = NULL, char *dst_ip = NULL, short eth_type = 0x0800, int sport = 0, int dport = 0,
                    unsigned char *payload = NULL, int payload_size = 0, unsigned long long data_array[] = NULL, unsigned long long ctrl_array[] = NULL)
{
    if (init_python_wrapper() != 0)
    {
        fprintf(stderr, "❌ Failed to initialize Python wrapper\n");
        return 1;
    }
    // const char *src_mac = "5a:51:52:53:56:55";  // sender MAC
    // const char *dst_mac  = "02:00:00:00:00:00";       // sender IP
    // const char *src_ip = "192.168.1.100";  // target MAC
    // const char *dst_ip  = "192.168.1.128";        // target IP
    // const int sport  = 5678;        // target IP
    // const int dport  = 1234;        // target IP
    // unsigned char payload[10];
    // for (int i = 0; i < 10; i++)
    // 	payload[i] = i; // example payload lengths

    // Build Python tuple of 7 args
    PyObject *args = PyTuple_New(8);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(src_mac));
    PyTuple_SetItem(args, 1, PyUnicode_FromString(dst_mac));
    PyTuple_SetItem(args, 2, PyUnicode_FromString(src_ip));
    PyTuple_SetItem(args, 3, PyUnicode_FromString(dst_ip));
    PyTuple_SetItem(args, 4, PyLong_FromLong(eth_type));
    PyTuple_SetItem(args, 5, PyLong_FromLong(sport));
    PyTuple_SetItem(args, 6, PyLong_FromLong(dport));

    // Send payload as bytes
    PyObject *py_payload_bytes = PyBytes_FromStringAndSize(
        (const char *)payload, // pointer to raw data
        payload_size           // 10 bytes
    );
    PyTuple_SetItem(args, 7, py_payload_bytes);

    // Call Python function with args
    PyObject *py_result = PyObject_CallObject(create_xgmii_eth_frame_func, args);
    if (!py_result)
    {
        PyErr_Print();
        fprintf(stderr, "❌ Python function call failed\n");
        cleanup_python_wrapper();
        return 1;
    }

    int size = convert_python_list_to_c_array(py_result, data_array, ctrl_array, 64);
    if (size < 0)
    {
        fprintf(stderr, "❌ Failed to convert Python list to C array\n");
        Py_DECREF(py_result);
        cleanup_python_wrapper();
        return 1;
    }

    // Print converted C array in hex
    // printf("✅ Got %d bytes from Python:\n", size);
    // for (int i = 0; i < size; i++) {
    // 	cout<< hex << data_array[i] << '\t' << ctrl_array[i] << endl;
    // }
    // printf("\n");

    Py_DECREF(py_result);
    cleanup_python_wrapper();
    return size; // return number of bytes in frame
}

int xgmii_to_udp(char *src_mac = NULL, char *dst_mac = NULL, char *src_ip = NULL, char *dst_ip = NULL,
                 unsigned long long data_array[] = NULL, unsigned long long ctrl_array[] = NULL)
{
    if (init_python_wrapper() != 0)
    {
        fprintf(stderr, "❌ Failed to initialize Python wrapper\n");
        return 1;
    }

    // Build Python tuple of 7 args
    PyObject *args = PyTuple_New(4);
    PyTuple_SetItem(args, 0, PyUnicode_FromString(src_mac));
    PyTuple_SetItem(args, 1, PyUnicode_FromString(dst_mac));
    PyTuple_SetItem(args, 2, PyUnicode_FromString(src_ip));
    PyTuple_SetItem(args, 3, PyUnicode_FromString(dst_ip));

    // Call Python function with args
    PyObject *py_result = PyObject_CallObject(decode_xgmii_frame_func, args);
    if (!py_result)
    {
        PyErr_Print();
        fprintf(stderr, "❌ Python function call failed\n");
        cleanup_python_wrapper();
        return 1;
    }

    int size = convert_python_list_to_c_array(py_result, data_array, ctrl_array, 64);
    if (size < 0)
    {
        fprintf(stderr, "❌ Failed to convert Python list to C array\n");
        Py_DECREF(py_result);
        cleanup_python_wrapper();
        return 1;
    }

    // Print converted C array in hex
    // printf("✅ Got %d bytes from Python:\n", size);
    // for (int i = 0; i < size; i++) {
    // 	cout<< hex << data_array[i] << '\t' << ctrl_array[i] << endl;
    // }
    // printf("\n");

    Py_DECREF(py_result);
    cleanup_python_wrapper();
    return size; // return number of bytes in frame
}

void mac_to_str(unsigned long long mac, char *buf)
{
    sprintf(buf, "%02llx:%02llx:%02llx:%02llx:%02llx:%02llx",
            (mac >> 40) & 0xff,
            (mac >> 32) & 0xff,
            (mac >> 24) & 0xff,
            (mac >> 16) & 0xff,
            (mac >> 8) & 0xff,
            mac & 0xff);
}
void ip_to_str(unsigned long ip, char *buf)
{
    sprintf(buf, "%u.%u.%u.%u",
            (ip >> 24) & 0xff,
            (ip >> 16) & 0xff,
            (ip >> 8) & 0xff,
            ip & 0xff);
}
int decode_xgmii_frame(unsigned long long data_array[], unsigned long long ctrl_array[],
                       int array_size, decoded_packet_t *result)
{
    // vpi_printf("Decoding XGMII frame of size: %d\n", array_size);
    // Initialize result structure
    memset(result, 0, sizeof(decoded_packet_t));

    if (init_python_wrapper() != 0)
    {
        fprintf(stderr, "❌ Failed to initialize Python wrapper\n");
        return -1;
    }

    // Create Python list of tuples for xgmii_words
    PyObject *xgmii_list = PyList_New(array_size);
    if (!xgmii_list)
    {
        fprintf(stderr, "❌ Failed to create Python list\n");
        cleanup_python_wrapper();
        return -1;
    }

    // Fill the list with (data, ctrl) tuples
    for (int i = 0; i < array_size; i++)
    {
        PyObject *tuple = PyTuple_New(2);
        PyTuple_SetItem(tuple, 0, PyLong_FromUnsignedLongLong(data_array[i]));
        PyTuple_SetItem(tuple, 1, PyLong_FromUnsignedLongLong(ctrl_array[i]));
        PyList_SetItem(xgmii_list, i, tuple);
    }

    // Create arguments tuple
    PyObject *args = PyTuple_New(1);
    PyTuple_SetItem(args, 0, xgmii_list);

    // Call Python decode function
    PyObject *py_result = PyObject_CallObject(decode_xgmii_frame_func, args);
    if (!py_result)
    {
        PyErr_Print();
        fprintf(stderr, "❌ Python decode function call failed\n");
        Py_DECREF(args);
        cleanup_python_wrapper();
        return -1;
    }

    // Check if result is a dictionary
    if (!PyDict_Check(py_result))
    {
        fprintf(stderr, "❌ Python function didn't return a dictionary\n");
        Py_DECREF(py_result);
        Py_DECREF(args);
        cleanup_python_wrapper();
        return -1;
    }

    // Extract fields from dictionary
    // Ethernet fields
    result->dst_mac = get_dict_ull(py_result, "dst_mac", 0);
    result->src_mac = get_dict_ull(py_result, "src_mac", 0);
    result->eth_type = (unsigned short)get_dict_long(py_result, "eth_type", 0);
    // ARP fields
    result->hwtype = (unsigned short)get_dict_long(py_result, "hwtype", 0);
    result->ptype = (unsigned short)get_dict_long(py_result, "ptype", 0);
    result->hwlen = (unsigned char)get_dict_long(py_result, "hwlen", 0);
    result->plen = (unsigned char)get_dict_long(py_result, "plen", 0);
    result->op = (unsigned short)get_dict_long(py_result, "op", 0);

    // IP fields
    result->version = (unsigned char)get_dict_long(py_result, "version", 0);
    result->ihl = (unsigned char)get_dict_long(py_result, "ihl", 0);
    result->tos_dscp = (unsigned char)get_dict_long(py_result, "tos_dscp", 0);
    result->tos_ecn = (unsigned char)get_dict_long(py_result, "tos_ecn", 0);
    result->length = (unsigned short)get_dict_long(py_result, "length", 0);
    result->identification = (unsigned short)get_dict_long(py_result, "identification", 0);
    result->flags = (unsigned char)get_dict_long(py_result, "flags", 0);
    result->fragment_offset = (unsigned short)get_dict_long(py_result, "fragment_offset", 0);
    result->ttl = (unsigned char)get_dict_long(py_result, "ttl", 0);
    result->protocol = (unsigned char)get_dict_long(py_result, "protocol", 0);
    result->header_checksum = (unsigned short)get_dict_long(py_result, "header_checksum", 0);
    result->source_ip = (unsigned int)get_dict_ull(py_result, "source_ip", 0);
    result->dest_ip = (unsigned int)get_dict_ull(py_result, "dest_ip", 0);

    // UDP fields
    result->source_port = (unsigned short)get_dict_long(py_result, "source_port", 0);
    result->dest_port = (unsigned short)get_dict_long(py_result, "dest_port", 0);
    result->udp_length = (unsigned short)get_dict_long(py_result, "udp_length", 0);
    result->udp_checksum = (unsigned short)get_dict_long(py_result, "udp_checksum", 0);

    // Payload
    result->payload_size = get_dict_bytes(py_result, "payload", result->payload, sizeof(result->payload));

    // Mark as valid if we got essential fields
    result->valid = (result->dst_mac != 0 && result->src_mac != 0) ? 1 : 0;

    // Cleanup
    Py_DECREF(py_result);
    Py_DECREF(args);
    cleanup_python_wrapper();

    return result->valid ? 0 : -1;
}

void print_decoded_packet(const decoded_packet_t *pkt)
{
    if (!pkt->valid)
    {
        // vpi_printf("❌ Invalid packet\n");
        return;
    }

    // vpi_printf("Decoded Packet:\n");
    // vpi_printf("  Ethernet: %012llx -> %012llx (type: 0x%04x)\n",
            //    pkt->src_mac, pkt->dst_mac, pkt->eth_type);
    // vpi_printf("  IP: %u.%u.%u.%u → %u.%u.%u.%u (proto: %d, len: %d)\n",
    //            (pkt->source_ip >> 24) & 0xFF, (pkt->source_ip >> 16) & 0xFF,
    //            (pkt->source_ip >> 8) & 0xFF, pkt->source_ip & 0xFF,
    //            (pkt->dest_ip >> 24) & 0xFF, (pkt->dest_ip >> 16) & 0xFF,
    //            (pkt->dest_ip >> 8) & 0xFF, pkt->dest_ip & 0xFF,
    //            pkt->protocol, pkt->length);
    // vpi_printf("  UDP: %d → %d (len: %d)\n",
    //            pkt->source_port, pkt->dest_port, pkt->udp_length);
    // vpi_printf("  Payload: %d bytes\n", pkt->payload_size);
}

extern "C" __declspec(dllexport) int xgmii_eth_frame_c(
    unsigned long long src_mac, unsigned long long dst_mac, unsigned long src_ip, unsigned long dst_ip, short eth_type,
    int sport, int dport, const svOpenArrayHandle payload, svOpenArrayHandle data, svOpenArrayHandle ctrl)
{
    char src_mac_str[18];
    char dst_mac_str[18];
    char src_ip_str[16];
    char dst_ip_str[16];

    // Convert integer MAC/IP to string format
    mac_to_str(src_mac, src_mac_str);
    mac_to_str(dst_mac, dst_mac_str);
    ip_to_str(src_ip, src_ip_str);
    ip_to_str(dst_ip, dst_ip_str);

    // Extract payload pointer and length
    unsigned char *payload_ptr = (unsigned char *)svGetArrayPtr(payload);
    int payload_len = svSize(payload, 1);

    // Debug: print first few payload bytes
    // for (int i = 0; i < payload_len; i++) {
    //     printf("Payload[%d] = %02x\n", i, payload_ptr[i]);
    // }

    // Extract data/ctrl output array pointers
    unsigned long long *data_ptr = (unsigned long long *)svGetArrayPtr(data);
    unsigned long long *ctrl_ptr = (unsigned long long *)svGetArrayPtr(ctrl);
    int frame_len = 0;
    // Call the actual XGMII frame builder
    return frame_len = xgmii_eth_frame(
               src_mac_str, dst_mac_str,
               src_ip_str, dst_ip_str, eth_type,
               sport, dport,
               payload_ptr, // <-- correct pointer now
               payload_len, // <-- pass payload length
               data_ptr,    // <-- correct pointer now
               ctrl_ptr     // <-- correct pointer now
           );

    // Debug: print generated data/ctrl
    // for (int i = 0; i < frame_len; i++) {
    // 	cout << hex << data_ptr[i] << '\t' << hex << ctrl_ptr[i] << endl;
    // }
}

extern "C" __declspec(dllexport) int scb_xgmii_to_udp(
    svOpenArrayHandle data,
    svOpenArrayHandle ctrl,
    // Ethernet
    unsigned long long *m_udp_eth_dest_mac,
    unsigned long long *m_udp_eth_src_mac,
    unsigned short *m_udp_eth_type,
    // ARP
    unsigned short *hwtype,
    unsigned short *ptype,
    unsigned char *hwlen,
    unsigned char *plen,
    unsigned short *op,
    // IP
    unsigned char *m_udp_ip_version,
    unsigned char *m_udp_ip_ihl,
    unsigned char *m_udp_ip_dscp,
    unsigned char *m_udp_ip_ecn,
    unsigned short *m_udp_ip_length,
    unsigned short *m_udp_ip_identification,
    unsigned char *m_udp_ip_flags,
    unsigned short *m_udp_ip_fragment_offset,
    unsigned char *m_udp_ip_ttl,
    unsigned char *m_udp_ip_protocol,
    unsigned short *m_udp_ip_header_checksum,
    unsigned int *m_udp_ip_source_ip,
    unsigned int *m_udp_ip_dest_ip,
    // UDP
    unsigned short *m_udp_source_port,
    unsigned short *m_udp_dest_port,
    unsigned short *m_udp_length,
    unsigned short *m_udp_checksum
)
{
    // Get array length
    // fprintf(stderr, "✅ scb_xgmii_to_udp called!\n");
    // fflush(stderr);

    int len = svSize(data, 1);
    // vpi_printf("Data received, length = %d\n", len);
    unsigned long long *data_ptr = (unsigned long long *)svGetArrayPtr(data);
    unsigned long long *cptr = (unsigned long long *)svGetArrayPtr(ctrl);
    if (!data_ptr || !cptr)
    {
        fprintf(stderr, "❌ svGetArrayPtr returned NULL!\n");
        return -1;
    }
    fprintf(stderr, "Data received from SV, length: %d\n", len);

    for (int i = 0; i < len; i++)
        printf("%d\t%x\t%x\n", i, data_ptr[i], (int)cptr[i]);

    decoded_packet_t packet;
    if (decode_xgmii_frame(data_ptr, cptr, len, &packet) == 0)
    {
        print_decoded_packet(&packet);

        // Use the decoded fields
        if (packet.dest_port == 1234)
        {
            printf("This is our target port!\n");
        }
    }
    else
    {
        printf("Failed to decode XGMII frame\n");
    }
    *m_udp_eth_dest_mac = packet.dst_mac;
    *m_udp_eth_src_mac = packet.src_mac;
    *m_udp_eth_type = packet.eth_type;
    *hwtype = packet.hwtype;
    *ptype = packet.ptype;
    *hwlen = packet.hwlen;
    *plen = packet.plen;
    *op = packet.op;
    *m_udp_ip_version = packet.version;
    *m_udp_ip_ihl = packet.ihl;
    *m_udp_ip_dscp = packet.tos_dscp;
    *m_udp_ip_ecn = packet.tos_ecn;
    *m_udp_ip_length = packet.length;
    *m_udp_ip_identification = packet.identification;
    *m_udp_ip_flags = packet.flags;
    *m_udp_ip_fragment_offset = packet.fragment_offset;
    *m_udp_ip_ttl = packet.ttl;
    *m_udp_ip_protocol = packet.protocol;
    *m_udp_ip_header_checksum = packet.header_checksum;
    *m_udp_ip_source_ip = packet.source_ip;
    *m_udp_ip_dest_ip = packet.dest_ip;
    *m_udp_source_port = packet.source_port;
    *m_udp_dest_port = packet.dest_port;
    *m_udp_length = packet.udp_length;
    *m_udp_checksum = packet.udp_checksum;
    return 10;
}
int main()
{
    return 0;
    // unsigned long long mac1 = 99305320044117ULL;  // some MAC as integer
    // unsigned long long mac2 = 2199023255552ULL;  // some MAC as integer
    // unsigned long ip1 = 3232235876;  //
    // unsigned long ip2 = 3232236033;  //
    // unsigned long long data_array[64];
    // unsigned long long ctrl_array[64];
    // char srcmac[18];  // "xx:xx:xx:xx:xx:xx" + '\0'
    // char dstmac[18];  // "xx:xx:xx:xx:xx:xx" + '\0'
    // char srcip[16];   // "xxx.xxx.xxx.xxx" + '\0'
    // char dstip[16];   // "xxx.xxx.xxx.xxx" + '\0'
    // mac_to_str(mac1, srcmac);
    // mac_to_str(mac2, dstmac);
    // ip_to_str(ip1, srcip);
    // ip_to_str(ip2, dstip);
    // printf("Source MAC string: %s\n", srcmac);
    // printf("Destination MAC string: %s\n", dstmac);
    // printf("Source IP string: %s\n", srcip);
    // printf("Destination IP string: %s\n", dstip);
    // // cout<< hex << mac1 << endl;
    // // cout<< hex << mac2 << endl;
    // return xgmii_eth_frame(srcmac, dstmac, srcip, dstip, 5678, 1234, (unsigned char *)"HelloWorld", data_array, ctrl_array);
}
