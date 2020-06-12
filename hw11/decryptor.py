import sys
import os
import string

class decryptor():
    def __init__(self):
        self.keyfile='./keydata.txt'
        self.key=''

    def get_keydata(self):
        f=open(self.keyfile,'rb')
        uu_id=f.readline()
        uu_key=f.readline()
        f.close()

        import base64
        self.key=base64.b64decode(uu_key)


    def decode(self,filename):
        from Crypto.Cipher import AES
        aes=AES.new(self.key[-16:],AES.MODE_ECB)

        f=open(filename,'rb')
        dump=f.read()
        f.close()

        decrypted=aes.decrypt(dump)
        f=open(filename+'.dc','wb')
        f.write(decrypted)
        f.close()


dc=decryptor()
dc.get_keydata()
dc.decode('./secrets.txt.enc')




